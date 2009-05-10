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
    # [+show+] if nil, all documents are returned; if :public only public are returned.  
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
    # [+folder_path+] Path in which to place the document initially (nil to use default)
    # [+template_id+] document id of a document to copy when initializing this new document (nil to make a blank one)
    # [+type+] If Gliffy ever supports other document types, use this
    #
    # Returns a document representing the document that was created.
    def document_create(name,folder_path=nil,template_id=nil,type=:diagram)
      params = { 
        :documentName => name,
        :documentType => type
      }
      params[:templateDiagramId] = template_id if !template_id.nil? 
      params[:folderPath] = normalize_folder_path(folder_path) if !folder_path.nil? 
      documents = make_request(:create,"#{account_url}/documents.xml",params)
      return nil if documents.nil? 
      documents[0]
    end

    # Delete an existing document
    def document_delete(document_id)
      make_request(:delete,document_url(document_id))
    end

    # Get meta-data about a document.
    # [+document_id+] identifier of the document
    # [+show_revisions+] if true, include info about the documents' revision history
    def document_get_metadata(document_id,show_revisions=false)
      make_request(:get,document_metadata_url(document_id),:showRevisions => show_revisions)[0]
    end

    # Get a document; returning the actual bytes
    # [+document_id+] identifier of the document
    # [+type+] document type.  Types known to work:
    #          [+:jpeg+] - JPEG
    #          [+:png+] - PNG
    #          [+:svg+] - SVG (for Visio import)
    #          [+:xml+] - Gliffy proprietary XML format (for archiving)
    # [+size+] size to show, from biggest to smallest: :L, :M, :S, :T
    # [+version+] The version to get, or nil to get the most recent
    def document_get(document_id,type=:jpeg,size=:L,version=nil)
      params = { :size => size }
      params[:version] = version if !version.nil?
      response = make_request(:get,document_url(document_id,type),params,false)
      if (type == :xml) || (type == :svg)
        response.body
      else
        response
      end
    end

    # Get a link to a document
    # [+document_id+] identifier of the document
    # [+type+] document type.  Types known to work:
    #          [+:jpg+] - JPEG
    #          [+:png+] - PNG
    #          [+:svg+] - SVG (for Visio import)
    #          [+:xml+] - Gliffy proprietary XML format (for archiving)
    # [+size+] size to show, from biggest to smallest: :L, :M, :S, :T
    # [+version+] The version to get, or nil to get the most recent
    def document_get_url(document_id,type=:jpg,size=:L,version=nil)
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

    # Update a document's meta-data or content
    # [+document_id+] identifier of document to update
    # [+options+] data to update; omission of an option will not change it
    #             [+:name+] change the name
    #             [+:public+] if false, will remove public statues, if true, will make public
    #             [+:content+] if present, should be the gliffy XML content to update (don't use this unless it's crucial)
    def document_update(document_id,options)
      if (options[:content])
        make_request(:update,document_url(document_id),{:content => options[:content]})
      end
      if (options[:name] || options[:public])
        params = {}
        params[:documentName] = options[:name] if options[:name]
        params[:public] = options[:public] if options[:public]
        make_request(:update,document_metadata_url(document_id),params)
      end
    end

    # Add a user to a folder
    def folder_add_user(path,username)
      make_request(:update,folder_users_url(path,username),{:read => true, :write => true})
    end

    # Create a new folder
    # [+path+] the path to the folder, each path separated by a forward slash.  If this starts with a forward slash
    #          it will attempt to make folder with the exact given path. This will probably fail.  If this DOESN'T
    #          start with a slash, this will make the folder inside ROOT, which is what you want.  So, don't
    #          start this with a slash.
    def folder_create(path)
      make_request(:create,"#{folders_url(path)}.xml")
    end

    # Delete a folder
    # [+path+] the path to the folder.  See folder_create.
    def folder_delete(path)
      make_request(:delete,"#{folders_url(path)}.xml")
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
    def folder_remove_user(path,username)
      make_request(:update,folder_users_url(path,username),{:read => false, :write => false})
    end

    # Create a new user
    # [+username+] the name to give this user
    def user_create(username)
      make_request(:create,"#{account_url}/users.xml",{ :userName => username })
    end

    # Delete an existing user
    def user_delete(username)
      make_request(:delete,"#{user_url(username)}.xml")
    end

    # Get the documents a user has access to (this is potentially expensive, as it results
    # in multiple calls to gliffy)
    # [username] if provided, get documents for the given username, otherwise get them for the logged-in user
    def user_documents(username='$username')
      return user_documents_helper(username,user_folders(username))
    end

    # Get the folders a user has access to
    # [username] if provided, get folders for the given username, otherwise get them for the logged-in user
    def user_folders(username='$username')
      make_request(:get,"#{user_url(username)}/folders.xml")
    end

    # Update a user's meta-data
    # [+username+] the username to operate on
    # [+options+] the options for updating their info.  Any omitted option will not change that value on the server.
    #             [+:email+] sets their email address
    #             [+:password+] sets their password for logging into gliffy.com
    #             [+:admin+] if true, sets them to be an admin; if false, revokes their admin privs
    def user_update(username,options)
      make_request(:update,user_url(username),options)
    end

    def anything(method,url,params={},parse=false,link=false)
      make_request(method,url,params,parse,link)
    end

    private 

    def account_url; 'accounts/$account_id'; end
    def user_url(username='$username'); "#{account_url}/users/#{username}/"; end
    def token_url; "#{user_url}/oauth_token.xml"; end
    def document_url(id,type=:xml); "#{account_url}/documents/#{id}.#{type.to_s}"; end
    def document_metadata_url(id); "#{account_url}/documents/#{id}/meta-data.xml"; end
    def folders_url(path=''); 
      path = normalize_folder_path(path)
      "#{account_url}/folders/#{path}"; 
    end
    def folder_users_url(path,username)
      folders_url(path) + "/users/#{username}.xml"
    end

    def user_documents_helper(username,folders)
      documents = []
      return documents if folders.nil?
      folders.each do |one_folder|
        docs = folder_documents(one_folder.path)
        if docs
          docs.each do |doc|
            documents << doc
          end
        end
        rest = user_documents_helper(username,one_folder.child_folders)
        rest.each { |d| documents << d} if rest
      end
      return documents
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

  ROOT_FOLDER = 'ROOT'
  # Prepends the path with "ROOT" if the path doesn't start with a slash
  def normalize_folder_path(path)
    return '' if path.nil? || path == ''
    if !(path =~ /^\//) && !(path =~ /^#{ROOT_FOLDER}$/) && !(path =~ /^#{ROOT_FOLDER}\//)
      path = "#{ROOT_FOLDER}/" + path 
    end
    path
  end
end
