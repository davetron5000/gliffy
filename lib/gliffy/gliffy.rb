require 'gliffy/rest'
require 'gliffy/response'
require 'gliffy/user'
require 'gliffy/diagram'
require 'gliffy/folder'
require 'gliffy/account'
require 'gliffy/config'

module Gliffy


  # A "handle" to access Gliffy on a per-user-session basis
  # Since most calls to gliffy require a user-token, this class
  # encapsulates that token and the calls made under it.
  #
  # The methods here are designed to raise exceptions if there are problems from Gliffy.
  # These problems usually indicate a programming error or a server-side problem with Gliffy and
  # are generally unhandleable.  However, if you wish to do something better than simply raise an exception
  # you may override handle_error to do something else
  #
  class Handle

    # Create a new handle to gliffy for the given user.  Tokens will be requested as needed
    def initialize(username)
      @username = username
      @rest = Rest.new
      @logger = Logger.new(Config.config.log_device)
      @logger.level = Config.config.log_level
      update_token(username)
    end

    # Run an arbitrary rest call against gliffy, parsing the result.  This allows you
    # essentially direct access to the underlying Gliffy::Rest, without having to worry about
    # setting it up.
    #
    # [+method+] a rest method, :get, :put, :post, :delete
    # [+url+] url to request, relative to Gliffy::Config#gliffy_root
    # [+params+] hash of parameters
    # [+headers+] hash of HTTP headers
    #
    # This will return a Gliffy::Response *if* the method you called returned XML.
    # If that is not what you want, you should use Gliffy::Rest.
    def rest_free(method,url,params={},headers={})
      Response.from_xml(do_simple_rest(method,url,"rest_free",params,headers))
    end

    # Adds a new user explicitly.  
    def add_user(username)
      do_user(:put,username)
    end

    # Deletes the user from this account.  May not be the user who owns the token for this
    # session (i.e. was passed to the constructor).  <b>This cannot be undone</b>.
    def delete_user(username)
      do_user(:delete,username)
    end

    # Allows +username+ to access +folder_path+ and all its child folders
    def add_user_to_folder(username,folder_path)
      do_user_folder(:put,username,folder_path)
    end

    # Revokes +username+ access to +folder_path+
    def remove_user_from_folder(username,folder_path)
      do_user_folder(:delete,username,folder_path)
    end

    # Creates a new blank diagram (or based on an existing one)
    #
    # [+diagram_name+] the name of the new diagram
    # [+template_diagram_id+] the id of a diagram to use as a template.  You must have access to this diagram
    #
    def create_diagram(diagram_name,template_diagram_id=nil)
      params = Hash.new
      params['diagramName'] = diagram_name
      params['templateDiagramId'] = template_diagram_id if template_diagram_id
      diagrams = do_simple_rest(:post,'diagrams',"Creating diagram named #{diagram_name}",params)
      if diagrams.size >= 1
        return diagrams[0]
      else
        raise "Got no diagrams, but creation was successful."
      end
    end

    # Creates a folder with the given name.  The parent path should already exist
    def create_folder(folder_path)
      do_folder(:put,folder_path)
    end

    # deletes the diagram with the given id.  <b>This cannot be undone</b>
    def delete_diagram(diagram_id)
      do_simple_rest(:delete,"diagrams/#{diagram_id}","Deleting diagram #{diagram_id}")
    end

    # Deletes a folder, moving all diagrams in it to the default folder. 
    # The folder must be empty
    # <b>This cannot be undone</b>
    def delete_folder(folder_path)
      folder_path = Folder.encode_path_elements(folder_path)
      do_simple_rest(:delete,"folders/#{folder_path}","Deleting folder #{folder_path}")
    end

    # Returns an array of User objects representing the admins of the account
    def get_admins
      do_simple_rest(:get,'admins','Getting admins for account')
    end

    # Gets the diagram as an image, possibly saving it to a file.
    #
    # [+diagram_id+] the id of the diagram to get
    # [+options+] a hash of options controlling the diagram and how it's fetched
    #             [<tt>:size</tt>] one of :thumbnail, :small, :medium, or :large (default is :large)
    #             [<tt>:file</tt>] if present, the diagram is written to the named file
    #             [<tt>:mime_type</tt>] the mime type to retrie.  You can also use :jpeg, :png and :svg as shortcuts (default is :jpeg)
    #             [<tt>:version</tt>] if present, the version number to retrieve (default is most recent)
    #
    # returns the bytes of the diagram if file was nil, otherwise, returns true
    #
    def get_diagram_as_image(diagram_id,options={:mime_type => :jpeg})
      params,headers = create_diagram_request_info(options)
      update_token
      bytes = @rest.get(url("diagrams/#{diagram_id}"),params,headers)
      if bytes.respond_to?(:success?) && !bytes.success?
        handle_error(bytes,"While getting bytes of diagram #{diagram_id}")
      else
        if options[:file]
          fp = File.new(options[:file],'w')
          fp.puts bytes
          fp.close
          true
        else
          bytes
        end
      end
    end

    # returns the URL that would get the diagram in question.  Same parameters as get_diagram_as_image
    def get_diagram_as_url(diagram_id,options={:mime_type => :jpeg})
      params,headers = create_diagram_request_info(options)
      update_token
      @rest.create_url(url("diagrams/#{diagram_id}"),params)
    end

    # GliffyDiagram getDiagramMetaData (integer $diagramId)
    def get_diagram_meta_data(diagram_id)
      params = {'diagramId' => diagram_id}
      diagrams = do_simple_rest(:get,'diagrams',"Getting meta data for diagram #{diagram_id}",params)
      diagrams[0]
    end

    # Gets a list of diagrams, either for the given folder, or the entire account
    def get_diagrams(folder_path=nil)
      folder_path = Folder.encode_path_elements(folder_path) if folder_path
      url = (folder_path ? "folders/#{folder_path}/" : "") + "diagrams"
      do_simple_rest(:get,url,"Get all folders in " + (folder_path ? folder_path : "account"))
    end

    # Gets the link that can be used <b>by this user while his token is valid</b> to edit the diagram.
    #
    # [+diagram_id+] the id of the diagram to edit
    # [+return_url+] if present represents the URL to return the user to after they have completed their editing.  You should not urlencode this, it will be done for you
    # [+return_text+] the text that should be used in Gliffy to represent the "return to the application" button.
    #
    # returns a Gliffy::LaunchLink that contains the complete URL to be used to edit the given diagram and behave as described.  The GliffyLaunchLink also contains the diagram name, which can be used for linking.  Note that the url is relative to the Gliffy website
    def get_edit_diagram_link(diagram_id,return_url=nil,return_text=nil)
      params = Hash.new
      params['returnURL'] = return_url if return_url
      params['returnText'] = return_text if return_text

      do_simple_rest(:get,"diagrams/#{diagram_id}/launchLink","Getting launch link for diagram #{diagram_id}",params)
    end

    # array getFolders ()
    def get_folders()
      do_simple_rest(:get,'folders','Getting folders for account')
    end

    # Gets the folders that +username+ has access to, in nested form
    def get_user_folders(username)
      do_simple_rest(:get,"users/#{username}/folders","Getting folders for user #{username}")
    end

    # Gets the users in the given folder, or in the entire account
    #
    # [+folder_path+] if present, returns users with access to this folder
    def get_users(folder_path=nil)
      url = ''
      if (folder_path)
        folder_path = Folder.encode_path_elements(folder_path)
        url += "folders/#{folder_path}/"
      end
      url += 'users'
      do_simple_rest(:get,url,"Getting users for " + (folder_path ? "folder #{folder_path}" : 'account'))
    end

    # returns true if the user currently has a token
    def has_token()
      !@rest.current_token.nil?
    end

    # move diagram +diagram_id+ to folder path +folder_path+
    def move_diagram(diagram_id,folder_path)
      folder_path = Folder.encode_path_elements(folder_path)
      do_simple_rest(:put,"folders/#{folder_path}/diagrams/#{diagram_id}","Moving #{diagram_id} to folder #{folder_path}")
    end

    # Updates the user.
    #
    # [+username+] user to update
    # [+attributes+] has of attributes to change.
    #                [<tt>:email</tt>] email address
    #                [<tt>:password</tt>] password for logging into Gliffy Online
    #                [<tt>:admin</tt>] true to make them an admin, false to revoke their admin-ness
    # 
    def update_user(username,attributes)
      params = Hash.new
      params['admin'] = attributes[:admin].to_s if attributes.has_key? :admin
      params['email'] = attributes[:email] if attributes[:email]
      params['password'] = attributes[:password] if attributes[:password]
      do_simple_rest(:put,"users/#{username}","Updating #{username}",params)
    end

    # Updates the user's token, if he needs it
    #
    #   [+force+] if true, the token is updated regardless
    def update_token(force=false)
      if force || !@rest.current_token || @rest.current_token.expired?
        @logger.debug('Forcing a new token') if force
        @logger.debug('No current token') if !@rest.current_token
        @rest.current_token = nil
        token = Response.from_xml(@rest.get(url("users/#{@username}/token")))
        if (token.success?)
          @logger.info("User #{@username} assigned token #{token.token} from Gliffy")
          @rest.current_token = token
        else
          handle_error(token)
        end
      else
        @logger.debug('Not getting a new token')
      end
    end

    # Override this if you want error handling that doesn't rasie an exception
    #
    # [+error_response+] an Error object that holds the error from Gliffy
    # [+action_cause+] a string describing the action being taken when the error ocurred
    def handle_error(error_response,action_cause=nil)
      msg = ""
      msg += "While #{action_cause}: " if action_cause
      msg += error_response.to_s
      raise msg
    end

    private

    def do_user(method,username)
      do_simple_rest(method,"users/#{username}","#{rest_to_text(method)} user #{username}")
    end

    def do_folder(method,folder_path)
      folder_path = Folder.encode_path_elements(folder_path)
      do_simple_rest(method,"folders/#{folder_path}","#{rest_to_text(method)} folder #{folder_path}")
    end

    def do_user_folder(method,username,folder_path)
      folder_path = Folder.encode_path_elements(folder_path)
      do_simple_rest(method,"folders/#{folder_path}/users/#{username}","#{rest_to_text(method)} #{username} to #{folder_path}")
    end

    def create_diagram_request_info(options)
      mime_type = options[:mime_type]
      params = Hash.new
      params['size'] = size_to_param(options[:size]) if options[:size]
      params['version'] = options[:version] if options[:version]
      headers = Hash.new
      if mime_type.is_a? Symbol
        headers['Accept'] = mime_type_to_header(mime_type)
      else
        headers['Accept'] = mime_type
      end
      [params,headers]
    end

    def do_simple_rest(method,url_fragment,description,params=nil,headers={})
      update_token
      response = Response.from_xml(@rest.send(method,url(url_fragment),params,headers))
      if !response.success?
        handle_error(response,description)
      end
      response
    end

    def url(fragment)
      "/accounts/#{Config.config.account_name}/#{fragment}"
    end

    def mime_type_to_header(mime_type_symbol)
      case mime_type_symbol
      when :jpeg: 'image/jpeg'
      when :jpg: 'image/jpeg'
      when :png: 'image/png'
      when :svg: 'image/svg+xml'
      else raise "#{mime_type_symbol} is not a known mime type"
      end
    end
    def size_to_param(size)
      return nil if !size
      case size 
      when :thumbnail: 'T'
      when :small: 'S'
      when :medium: 'M'
      when :large: 'L'
      else raise "#{size} is not a supported size"
      end
    end

    def rest_to_text(method)
      case method
      when :put : 'Creating'
      when :delete : 'Deleting'
      when :post : 'Updating'
      when :get : 'Getting'
      else
        raise "Unknown method #{method.to_s}"
      end
    end


  end
end
