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
  class Handle

    def initialize(username)
      @username = username
      @rest = Rest.new
      @logger = Logger.new(Config.config.log_device)
      @logger.level = Config.config.log_level
      update_token(username)
    end

    # boolean addUser (string $username)
    def add_user(username)
      do_simple_rest(:put,url("users/#{username}"),"Create user #{username}")
    end

    def do_simple_rest(method,url_fragment,description,params=nil)
      update_token
      response = Response.from_xml(@rest.send(method,url(url_fragment),params))
      if !response.success?
        handle_error(response,description)
      end
      response
    end

    # void addUserToFolder (string $folderName, string $username)
    def add_user_to_folder(folder_name,username)
    end

    # integer createDiagram (string $diagramName, [int $templateDiagramId = 0])
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

    # void createFolder (string $folderName)
    def create_folder(folder_name)
    end

    # void deleteDiagram (integer $diagramId)
    def delete_diagram(diagram_id)
      do_simple_rest(:delete,"diagrams/#{diagram_id}","Deleting diagram #{diagram_id}")
    end

    # void deleteFolder (string $folderName)
    def delete_folder(folder_name)
    end

    # void deleteUser (string $username)
    def delete_user(username)
    end

    # array getAdmins ()
    def get_admins
      do_simple_rest(:get,'admins','Getting admins for account')
    end

    # Gets the diagram as an image, possibly saving it to a file.
    #
    #   [diagram_id] the id of the diagram to get
    #   [options] a hash of options controlling the diagram and how it's fetched
    #     [:size] one of :thumbnail, :small, :medium, or :large (default is :large)
    #     [:file] if present, the diagram is written to the named file
    #     [:mime_type] the mime type to retrie.  You can also use :jpeg, :png and :svg as shortcuts (default is :jpeg)
    #     [:version] if present, the version number to retrieve (default is most recent)
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

    # string getDiagramAsURL (integer $diagramId, [string $mime_type = Gliffy::MIME_TYPE_JPEG], [string $size = null], [string $version = null], [boolean $force = false])
    def get_diagram_as_url(diagram_id,options={:mime_type => :jpeg})
      params,headers = create_diagram_request_info(options)
      update_token
      @rest.create_url(url("diagrams/#{diagram_id}"),params)
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

    # GliffyDiagram getDiagramMetaData (integer $diagramId)
    def get_diagram_meta_data(diagram_id)
    end

    # array getDiagrams ([string $folderName = null])
    def get_diagrams(folder_name=nil)
    end

    # GliffyLaunchLink getEditDiagramLink (integer $diagramId, [string $returnURL = null], [string $returnText = null])
    def get_edit_diagram_link(diagram_id,return_URL=nil,return_text=nil)
    end

    # array getFolders ()
    def get_folders()
    end

    # array getUserDiagrams ([string $username = null])
    def get_user_diagrams(username=nil)
    end

    # array getUserFolders (string $username)
    def get_user_folders(username)
    end

    # array getUsers ([string $folderName = null])
    def get_users(folder_name=nil)
    end

    # void hasToken ()
    def has_token()
      !@rest.current_token.nil?
    end

    # void moveDiagram (integer $diagramId, string $folderName)
    def move_diagram(diagram_id,folder_name)
    end

    # void removeUserFromFolder (string $folderName, stinrg $username)
    def remove_user_from_folder(folder_name,username)
    end

    # void updateUser (string $username, [boolean $admin = null], [string $email = null], [string $password = null])
    def update_user(username,admin=nil,email=nil,password=nil)
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
        @logger.debug('Not getting a new token');
      end
    end

    # Override this if you want error handling that doesn't rasie an exception
    def handle_error(error_response,action_cause=nil)
      msg = ""
      msg += "While #{action_cause}" if action_cause
      msg += error_response.to_s
      raise msg
    end

    private

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

  end
end
