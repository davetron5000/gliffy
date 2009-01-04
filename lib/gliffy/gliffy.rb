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
    #   [mime_type] the mime type, either :jpeg, :png, or an actual mime type string
    #   [file] if non-nil the name of the file to write the diagram to.
    #   [size] the size of the diagram.  Currently supports :thumbnail, :small, :medium, and :large.  This sizes are porportions based on the diagram's size.  This is ignored if the mime type doesn't support it (e.g. SVG).  Null indicates to use Gliffy's default.
    #   [version] the version to get.  A value less than or equal to the "num versions" of the diagram will be valid.  This is one-based.  A value of nil means to get the most recent version
    #
    # returns the bytes of the diagram if file was nil, otherwise, returns true
    #
    def get_diagram_as_image(diagram_id,mime_type=:jpeg,file=nil,size=nil,version=nil)
    end

    # string getDiagramAsURL (integer $diagramId, [string $mime_type = Gliffy::MIME_TYPE_JPEG], [string $size = null], [string $version = null], [boolean $force = false])
    def get_diagram_as_URL(diagram_id,mime_type=:jpeg,size=nil,version=nil,force=false)
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

    protected

    def url(fragment)
      "/accounts/#{Config.config.account_name}/#{fragment}"
    end
  end
end
