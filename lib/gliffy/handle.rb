require 'gliffy/request'
require 'gliffy/response'
require 'gliffy/credentials'

module Gliffy
  VERSION = '0.1.7'


  # A "handle" to access Gliffy on a per-user-session basis
  # Since most calls to gliffy require a user-token, this class
  # encapsulates that token and the calls made under it.
  #
  class Handle

    attr_reader :logger
    attr_reader :request
    attr_reader :token

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
      make_request(:get,"#{account_url}/users.xml")
    end

    # Create a new document
    def document_create(name,folder_path=nil,template_id=nil,type=:document)
      params = { 
        :documentName => name,
        :documentType => type
      }
      params[:templateDiagramId] = template_id if !template_id.nil? 
      params[:folderPath] = folder_path if !folder_path.nil? 
      make_request(:create,"#{account_url}/documents.xml",params)
    end

    # Delete an existing document
    def document_delete
    end

    def document_get_metadata(document_id,show_revisions=:false)
      make_request(:get,document_url(document_id),:showRevisions => show_revisions)
    end

    # Get a document; returning the actual bytes
    def document_get(document_id,type=:jpeg,size=:L,version=nil)
      params = { :size => size }
      params[:version] = version if !version.nil?
      make_request(:get,document_url(document_id,type),params,false)
    end

    # Get a link to a document
    def document_get_url(document_id,type=:jpeg,size=:L,version=nil)
      params = { :size => size }
      params[:version] = version if !version.nil?
      make_request(:get,document_url(document_id,type),params,false,true)
    end

    # Get the link to edit a document
    def document_edit_link
    end

    # Move a document to a different folder
    def document_move
    end

    # Update a document's XML content
    def document_update_content
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
    def folder_users(path)
      make_request(:get,"#{folders_url(path)}/users.xml")
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
    def user_folders(username='$username')
      make_request(:get,"#{user_url(username)}/folders.xml")
    end

    # Update a user's meta-data
    def user_update
    end

    private 

    def account_url; 'accounts/$account_id'; end
    def user_url(username='$username'); "#{account_url}/users/#{username}/"; end
    def token_url; "#{user_url}/oauth_token.xml"; end
    def document_url(id,type=:xml); "#{account_url}/documents/#{id}.#{type.to_s}"; end
    def folders_url(path=''); "#{account_url}/folders/#{path}"; end

    def make_request(method,url,params=nil,parse=true,link_only=false)
      update_token
      if link_only
        @request.link_for(method,url,params)
      else
        @logger.debug("Requesting #{url} with {#params.inspect}")
        response = @request.send(method,url,params)
        @logger.debug("Got back #{response.body}")
        if parse
          Response.from_http_response(response)
        else
          response
        end
      end
    end

  end
end
