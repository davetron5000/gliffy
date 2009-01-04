require 'rexml/document'
require 'array_has_response'
require 'gliffy/rest'

include REXML

module Gliffy

  # Base class for Gliffy response.  This class is also the entry point
  # for parsing Gliffy XML:
  #    
  #     xml = get_xml_from_gliffy
  #     response = self.from_xml(xml)
  #     # response is now a Response or subclass of response
  #     if response.success?
  #       if response.not_modified?
  #         # use the item(s) from your local cache
  #       else
  #         # it should be what you expect, e.g. Diagram, array of Users, etc.
  #       end
  #     else
  #       puts response.message # in this case it's an Error
  #     end
  #
  #
  class Response

    # Creates a Response based on the XML passed in.
    # The xml can be anything passable to REXML::Document.new, such as
    # a Document, or a string containing XML
    #
    # This will return a Response, a subclass of Response, or an array of
    # Response/subclass of Response objects.  In the case where an array is returned
    # both success? and not_modified? may be called, so the idiom in the class Rdoc should
    # be usable regardless of return value
    def self.from_xml(xml)
      raise ArgumentError.new("xml may not be null to #{to_s}.from_xml") if !xml
      root = Document.new(xml).root
      not_modified = root.attributes['not-modified'] == "true"
      success = root.attributes['success'] == "true"

      response = nil
      if ! root.elements.empty?
        klassname = to_classname(root.elements[1].name)
        klass = Gliffy.const_get(klassname)
        response = klass.from_xml(root.elements[1])
      else
        response = Response.new
      end

      response.success = success
      response.not_modified = not_modified

      response
    end

    # Returns true if the response represents a successful response
    # false indicates failure and that element is most likely a Error
    def success?; @success; end

    # Returns true if this response indicates the requested resource
    # was not modified, based on the headers provided with the request.
    def not_modified?; @not_modified; end

    def success=(s); @success = s; end
    def not_modified=(s); @not_modified = s; end

    # Provides access to the rest implementation
    def self.rest; @@rest; end

    protected

    @@rest=Gliffy::Rest.new

    def initialize
      @success = true
      @not_modified = false
    end

    # Converts a dash-delimited string to a camel-cased classname
    def self.to_classname(name)
      classname = ""
      name.split(/-/).each do |part|
        classname += part.capitalize
      end
      classname
    end
  end

  # Represents on account
  class Account < Response

    attr_reader :name
    attr_reader :id
    # Either :basic or :premium
    attr_reader :type
    attr_reader :max_users
    # A Time representing the date on which this account expires
    attr_reader :expiration_date
    # Returns a Users representing the users that
    # were included.  If users were not included
    # in the response, this will be an empty array
    attr_reader :users

    def self.from_xml(element)
      id = element.attributes['id'].to_i
      type = element.attributes['account-type']
      if type == 'Basic'
        type = :basic
      elsif type == 'Premium'
        type = :premium
      else
        raise "Unknown type #{type}"
      end
      max_users = element.attributes['max-users'].to_i
      expiration_date = Time.at(element.elements['expiration-date'].text.to_i / 1000)
      name = element.elements['name'].text
      users = Users.from_xml(element.elements['users'])

      Account.new(id,type,name,max_users,expiration_date,users)
    end

    # Finds an account named account_name.  Will always return a Response instance.
    def self.find(account_name)
      accounts = Response.from_xml(@@rest.get("/accounts/#{account_name}",{'showUsers' => 'true'}))
      if (accounts.success?)
        accounts.each { |account| return account if account.name == account_name }
        return Error.new("No account named #{account_name}",404)
      else
        return accounts
      end
    end

    # Re-fetches the users from the server
    def users!
      new_users = Response.from_xml(@@rest.get(create_url("users")))
      if (new_users.success?)
        @users=new_users
      else
        return new_users
      end
      @users
    end

    # Returns the diagrams last retrieved by the server
    def diagrams
      if !@diagrams
        diagrams!
      else
        @diagrams
      end
    end

    # Re-fetches the diagrams from the server
    def diagrams!
      new_diagrams = Response.from_xml(@@rest.get(create_url("diagrams")))
      if (new_diagrams.success?)
        @diagrams=new_diagrams
      else
        return new_diagrams
      end
      @diagrams
    end

    protected

    def create_url(url_fragment="")
      "/accounts/#{name}/#{url_fragment}"
    end

    def initialize(id,type,name,max_users,expiration_date,users=nil)
      super()
      @id = id
      @type = type
      @name = name
      @max_users = max_users
      @expiration_date = expiration_date
      @users = users
    end

  end


  # A gliffy diagram (or, rather, the meta data about that diagram)
  class Diagram < Response

    attr_reader :id
    attr_reader :num_versions
    attr_reader :name
    # The username of the proper owner of this diagram
    attr_reader :owner_username
    # A Time representing the date on which this diagram was created
    attr_reader :create_date
    # A Time representing the date on which this diagram was last modified
    attr_reader :mod_date
    # A Time representing the date on which this diagram was published,
    # or nil if it was not published
    attr_reader :published_date

    def self.from_xml(element)
      id = element.attributes['id'].to_i
      num_versions = element.attributes['num-versions'].to_i
      is_private = element.attributes['is-private'] == "true"
      is_public = element.attributes['is-public'] == "true"

      create_date = Time.at(element.elements['create-date'].text.to_i / 1000)
      mod_date = Time.at(element.elements['mod-date'].text.to_i / 1000)
      published_date = element.elements['published-date'] ? Time.at(element.elements['published-date'].text.to_i / 1000) : nil
      name = element.elements['name'].text
      owner_username = element.elements['owner'] ? element.elements['owner'].text : nil

      Diagram.new(id,name,owner_username,is_public,is_private,num_versions,create_date,mod_date,published_date)
    end

    # True if this diagram is public
    def is_public?
      @is_public
    end

    # True if this diagram is private (and available only
    # to the owner and account administrators)
    def is_private?
      @is_private
    end

    protected 
    def initialize(id,name,owner_username,is_public,is_private,num_versions,create_date,mod_date,published_date)
      super()
      @id = id
      @name = name
      @owner_username = owner_username
      @is_public = is_public
      @is_private = is_private
      @num_versions = num_versions
      @create_date = create_date
      @mod_date = mod_date
      @published_date = published_date
    end

  end

  # A link to edit a specific gliffy diagram
  class LaunchLink < Response

    # The name of the diagram, which can helpful
    # in creating HTML hyperlinks to url
    attr_reader :diagram_name
    attr_reader :url

    def self.from_xml(element)
      diagram_name = element.attributes['diagram-name']
      url = element.text
      LaunchLink.new(diagram_name,url)
    end

    protected

    def initialize(name,url)
      super()
      @diagram_name = name
      @url = url
    end
  end

  # A user token
  class UserToken < Response
    attr_reader :expiration
    attr_reader :token
    def self.from_xml(element)
      expiration = Time.at(element.attributes['expiration'].to_i / 1000)
      token = element.text
      UserToken.new(expiration,token)
    end

    protected

    def initialize(expiration,token)
      super()
      @expiration = expiration
      @token = token
    end

  end

  class ArrayResponseParser
    def self.from_xml(element)
      single_classname = self.to_s.gsub(/s$/,'').gsub(/Gliffy::/,'')
      klass = Gliffy.const_get(single_classname)
      list = Array.new
      if (element)
        element.each_element do |element|
          list << klass.from_xml(element)
        end
      end
      list
    end
  end

  class Folders < ArrayResponseParser; end
  class Diagrams < ArrayResponseParser; end
  class Accounts < ArrayResponseParser; end
  class Users < ArrayResponseParser; end

  class Folder < Response

    # An array of Folder objects that are contained within this folder
    # If this is empty, it means this Folder is a leaf
    attr_reader :child_folders
    attr_reader :id
    attr_reader :name
    # The full path to this folder within the account's 
    # folder hierarchy
    attr_reader :path

    def self.from_xml(element)
      id = element.attributes['id'].to_i
      default = element.attributes['is-default'] == "true"
      name = element.elements['name'].text
      path = element.elements['path'].text
      child_folders = Array.new
      element.each_element do |element|
        child_folders << Folder.from_xml(element) if element.name == "folder"
      end
      Folder.new(id,name,default,path,child_folders)
    end

    # Returns true if this folder is the default folder
    # used when an operation requiring a folder
    # doesn't specify one (such as when creating a new
    # diagram)
    def default?
      @default
    end

    protected 

    def initialize(id,name,default,path,child_folders)
      super()
      @id = id
      @name = name
      @default = default
      @path = path
      @child_folders = child_folders
    end
  end

  # A user of Gliffy
  class User < Response

    # The user's username, which is their identifier within an account
    attr_reader :username
    # The user's email, which is unique to them in the entire Gliffy system.
    # Note that this isn't guaranteed to be a real email, nor is
    # it guaranteed to be the user's actual email.  This is 
    # assigned by the system unless overridden by the API.
    attr_reader :email
    attr_reader :id

    def self.from_xml(element)
      id = element.attributes['id'].to_i
      is_admin = false
      is_admin = element.attributes['is-admin'] == 'true' if element.attributes['is-admin'] 
      username = element.elements['username'] ? element.elements['username'].text : nil
      email = element.elements['email'] ? element.elements['email'].text : nil

      User.new(id,is_admin,username,email)
    end

    # Returns true if this user is an admin of the account in which they live
    def is_admin?
      @is_admin
    end

    protected

    def initialize(id,is_admin,username,email)
      super()
      @id = id
      @is_admin = is_admin
      @username = username
      @email = email
    end

  end

  # An error from Gliffy
  class Error < Response
    # The HTTP status code that can help indicate the nature of the problem
    attr_reader :http_status
    # A description of the error that occured; not necessarily for human
    # consumption
    attr_reader :message

    def self.from_xml(element)
      message = element.text
      http_status = element.attributes['http-status'].to_i
      Error.new(message,http_status)
    end

    def initialize(message,http_status)
      super()
      @message = message
      @http_status = http_status
    end

  end
end
