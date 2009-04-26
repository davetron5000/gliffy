require 'gliffy/request'
require 'gliffy/response'
require 'gliffy/credentials'

module Gliffy
  VERSION = '0.1.7'


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

    attr_reader :logger
    attr_reader :request
    attr_reader :token

    # Create a new handle to gliffy for the given user.  Tokens will be requested as needed
    def initialize(api_root,credentials,http=nil,logger=nil)
      @credentials = credentials
      @request = Request.new(api_root,credentials)
      @request.http = http if !http.nil?
      @logger = logger || Logger.new(STDOUT)
      @logger.level = Logger::INFO
      @request.logger = @logger
      if !@credentials.has_access_token?
        update_token
      end

    end


    # Updates the token being used if there isn't one in the 
    # credentials, or by forcing
    # [+force+] always attempt to update the token
    def update_token(force=false)
      if !@credentials.has_access_token? || force
        @logger.debug("Requesting new token " + (force ? " by force " : " since we have none "))
        response = @request.create(token_url,
                                   :description => @credentials.description,
                                   :protocol_override => :https)
        @token = Response.from_http_response(response)
        @credentials.update_access_token(@token)
      end
    end

    # Delete the current token
    def delete_token
      make_request(:delete,token_url)
      @credentials.clear_access_token
    end

    # Get admins of your account.  Returns users
    def account_admins
      make_request(:get,"#{account_url}/admins.xml")
    end

    # Returns all documents in the account
    # [+show+] if nil, all documents are returned; if :public only public are returned.  If :private only non-public are returned.
    def account_documents(show=nil)
      if show.nil?
        make_request(:get,"#{account_url}/documents.xml")
      else
        make_request(:get,"#{account_url}/documents.xml",:public => show == :public)
      end
    end

    # Returns all folders in the account
    def account_folders
      make_request(:get,"#{account_url}/folders.xml")
    end

    # Returns account meta data
    def account_get(show_users=true)
      make_request(:get,"#{account_url}.xml", :showUsers => show_users)
    end

    # Get users in your account
    def account_users 
    end


    # Create a new diagram
    def diagram_create
    end

    # Delete an existing diagram
    def diagram_delete
    end

    # Get a diagram
    def diagram_get
    end

    # Get a link to a diagram
    def diagram_get_url
    end

    # Get the link to edit a diagram
    def diagram_edit_link
    end

    # Move a diagram to a different folder
    def diagram_move
    end

    # Update a diagram's XML content
    def diagram_update_content
    end

    # Add a user to a folder
    def folder_add_user
    end

    # Create a new folder
    def folder_create
    end

    # Delete a folder
    def folder_delete
    end

    # Get the documents in a folder
    def folder_documents
    end

    # Get users with access to the folder
    def folder_users
    end

    # Remove a user from access to the folder
    def folder_remove_user
    end

    # Create a new user
    def user_add
    end

    # Delete an existing user
    def user_delete
    end

    # Get the documents a user has access to
    def user_documents
    end

    # Get the folders a user has access to
    def user_folders
    end

    # Update a user's meta-data
    def user_update
    end

    private 

    def account_url; 'accounts/$account_id'; end
    def token_url; "#{account_url}/users/$username/oauth_token.xml"; end

    def make_request(method,url,params=nil)
      update_token
      @logger.debug("Requesting #{url} with {#params.inspect}")
      response = @request.send(method,url,params)
      @logger.debug("Got back #{response.body}")
      Response.from_http_response(response)
    end

  end
end
