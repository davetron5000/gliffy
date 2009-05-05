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

    # Get access to the logger (useful for controlling log messages)
    attr_reader :logger
    # Get access to the Request (useful for hacking or testing)
    attr_reader :request
    # Get access to the current token (useful for caching to disk)
    attr_reader :token

    # Use this to override what happens when an error from Gliffy is received.
    # The default (or nil) is to raise the exception that was generated.
    # If you want to override this provide a block that takes the response that was
    # received (which will be a hash-like object from HTTParty, possibly nil) and
    # the exception that was generated (the message of which will have been parsed
    # from Gliffy's XML if that was possible):
    #     
    #     # If we got an HTTParty response, try to print out the body and the Gliffy message
    #     # Otherwise, barf
    #     handle.response = Proc.new do |response,exception|
    #       if response && response.respond_to? :body
    #         puts exception.to_str
    #         puts response.body
    #       else
    #         raise exception
    #       end
    #     end
    attr_writer :error_callback

    # Create a new handle to Gliffy
    # [+api_root+] root URL (without the protocol) of where to connect to Gliffy
    # [+credentials+] a Credentials object to use for access
    # [+http+] override of http access class (use at your own risk; must be substituable for HTTPart)
    # [+logger+] logger instance, if you don't want the default
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
      @error_callback = nil
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
    # [+show_users+] if true, include the list of users in this account
    def account_get(show_users=true)
      make_request(:get,"#{account_url}.xml", :showUsers => show_users)[0]
    end

    # Get users in your account
    def account_users 
      make_request(:get,"#{account_url}/users.xml")
    end

    # Create a new document
    # [+name+] Name of the new document
    # [+folder_path+] Path in which to place the document initially
    # [+template_id+] document id of a document to copy when initializing this new document
    # [+type+] If Gliffy ever supports other document types, use this
    def document_create(name,folder_path=nil,template_id=nil,type=:diagram)
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
      raise "Not Implemented"
    end

    # Get meta-data about a document.
    # [+document_id+] identifier of the document
    # [+show_revisions+] if true, include info about the documents' revision history
    def document_get_metadata(document_id,show_revisions=false)
      make_request(:get,document_url(document_id),:showRevisions => show_revisions)[0]
    end

    # Get a document; returning the actual bytes
    # [+document_id+] identifier of the document
    # [+type+] document type.  Types known to work:
    #          [+:jpeg+]
    #          [+:png+]
    #          [+:svg+]
    #          [+:xml+]
    #          [+:xml+]
    # [+size+] size to show, from biggest to smallest: :L, :M, :S, :T
    # [+version+] The version to get, or nil to get the most recent
    def document_get(document_id,type=:jpeg,size=:L,version=nil)
      params = { :size => size }
      params[:version] = version if !version.nil?
      make_request(:get,document_url(document_id,type),params,false)
    end

    # Get a link to a document
    # [+document_id+] identifier of the document
    # [+type+] document type.  Types known to work:
    #          [+:jpeg+]
    #          [+:png+]
    #          [+:svg+]
    #          [+:xml+]
    #          [+:xml+]
    # [+size+] size to show, from biggest to smallest: :L, :M, :S, :T
    # [+version+] The version to get, or nil to get the most recent
    def document_get_url(document_id,type=:jpeg,size=:L,version=nil)
      params = { :size => size }
      params[:version] = version if !version.nil?
      make_request(:get,document_url(document_id,type),params,false,true)
    end

    # Get the link to edit a document
    def document_edit_link
      raise "Not Implemented"
    end

    # Move a document to a different folder
    def document_move
      raise "Not Implemented"
    end

    # Update a document's XML content
    def document_update_content
      raise "Not Implemented"
    end

    # Add a user to a folder
    def folder_add_user
      raise "Not Implemented"
    end

    # Create a new folder
    def folder_create
      raise "Not Implemented"
    end

    # Delete a folder
    def folder_delete
      raise "Not Implemented"
    end

    # Get the documents in a folder
    # [+path+] the path to the folder whose documents to get
    def folder_documents(path)
      make_request(:get,"#{folders_url(path)}/documents.xml")
    end

    # Get users with access to the folder
    # [+path+] the path to the folder whose users to get
    def folder_users(path)
      make_request(:get,"#{folders_url(path)}/users.xml")
    end

    # Remove a user from access to the folder
    def folder_remove_user
      raise "Not Implemented"
    end

    # Create a new user
    def user_add
      raise "Not Implemented"
    end

    # Delete an existing user
    def user_delete
      raise "Not Implemented"
    end

    # Get the documents a user has access to
    # [username] if provided, get documents for the given username, otherwise get them for the logged-in user
    def user_documents(username='$username')
      user_documents_helper(username,user_folders(username)).values
    end

    # Get the folders a user has access to
    # [username] if provided, get folders for the given username, otherwise get them for the logged-in user
    def user_folders(username='$username')
      make_request(:get,"#{user_url(username)}/folders.xml")
    end

    # Update a user's meta-data
    def user_update
      raise "Not Implemented"
    end

    private 

    def account_url; 'accounts/$account_id'; end
    def user_url(username='$username'); "#{account_url}/users/#{username}/"; end
    def token_url; "#{user_url}/oauth_token.xml"; end
    def document_url(id,type=:xml); "#{account_url}/documents/#{id}.#{type.to_s}"; end
    def folders_url(path=''); "#{account_url}/folders/#{path}"; end

    def user_documents_helper(username,folders)
      if folders.nil?
        {}
      else
        documents = {}
        folders.each do |one_folder|
          docs = folder_documents(one_folder.path)
          docs.each do |doc|
            documents[doc.document_id] = doc
          end
          documents.merge!(user_documents_helper(username,one_folder.child_folders))
        end
        documents
      end
    end


    # Handles the mechanics of making the request
    # [+method+] the gliffy "action"
    # [+url+] the url, relative to the gliffy API root, no params/query string stuff
    # [+params+] hash of parameters
    # [+parse+] if true, request is parsed; set to false to get the raw result back
    # [+link_only+] don't make a request just send the full link (useful for <img> tags)
    def make_request(method,url,params=nil,parse=true,link_only=false)
      update_token
      if link_only
        @request.link_for(method,url,params)
      else
        @logger.debug("Requesting #{url} with {#params.inspect}")
        response = @request.send(method,url,params)
        @logger.debug("Got back #{response.body}")
        if parse
          Response.from_http_response(response,@error_callback)
        else
          response
        end
      end
    end
  end
end
