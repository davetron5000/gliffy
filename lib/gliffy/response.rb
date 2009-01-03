require 'rexml/document'
include REXML

module Gliffy

  # Encapsulates a response from Gliffy.  The element accessor provides
  # access to the actual element in question.  The class method
  # of element can provide you information as to what the response is
  # (though it should be known from context).  Instances can
  # be obtained via the parse method.
  class Response

    # Creates a Response based on the XML passed in.
    # The xml can be anything passable to REXML::Document.new, such as
    # a Document, or a string containing XML
    def self.parse(xml)
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

    protected

    def initialize; end


    # Converts a dash-delimited string to a camel-cased classname
    def self.to_classname(name)
      classname = ""
      name.split(/-/).each do |part|
        classname += part.capitalize
      end
      classname
    end
  end

  # Defines basic array operations needed by 
  # the various container classes.
  # To mix this in, define a member variable
  # @list, that contains the items in the array.
  module ContainerArray
    def each
      @list.each { |item| yield item }
    end

    def <<(element)
      @list << element
    end

    def [](index)
      @list[index]
    end

    def length
      @list.length
    end
  end

  # Represents a list of Account objects
  class Accounts < Response

    include Enumerable
    include ContainerArray

    def self.from_xml(element)
      accounts = Accounts.new
      element.each_element do |element|
        accounts << Account.from_xml(element)
      end
      accounts
    end

    protected

    def initialize; @list = Array.new; end

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

    def initialize(id,type,name,max_users,expiration_date,users=nil)
      @id = id
      @type = type
      @name = name
      @max_users = max_users
      @expiration_date = expiration_date
      @users = users
    end

  end

  # A list of Diagram objects
  class Diagrams < Response

    include Enumerable
    include ContainerArray

    def self.from_xml(element)
      diagrams = Diagrams.new
      if (element)
        element.each_element do |element|
          diagrams << Diagram.from_xml(element)
        end
      end
      diagrams
    end

    protected

    def initialize; @list = Array.new; end

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

    def initialize(id,name,owner_username,is_public,is_private,num_versions,create_date,mod_date,published_date)
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

    # True if this diagram is public
    def is_public?
      @is_public
    end

    # True if this diagram is private (and available only
    # to the owner and account administrators)
    def is_private?
      @is_private
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
      @expiration = expiration
      @token = token
    end

  end

  # A list of folders.  Note that this only
  # represents the top level access to the folders
  # (see Folder below)
  class Folders < Response

    include Enumerable
    include ContainerArray

    def self.from_xml(element)
      folders = Folders.new
      if (element)
        element.each_element do |element|
          folders << Folder.from_xml(element)
        end
      end
      folders
    end

    protected

    def initialize; @list = Array.new; end


  end

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

    def initialize(id,name,default,path,child_folders)
      @id = id
      @name = name
      @default = default
      @path = path
      @child_folders = child_folders
    end


    # Returns true if this folder is the default folder
    # used when an operation requiring a folder
    # doesn't specify one (such as when creating a new
    # diagram)
    def default?
      @default
    end

    def handle=(handle)
      @handle = handle
      @child_folders.each() { |child| child.handle=handle }
    end
  end

  # A list of User objects
  class Users < Response

    include Enumerable
    include ContainerArray

    def self.from_xml(element)
      users = Users.new
      if (element)
        element.each_element do |element|
          users << User.from_xml(element)
        end
      end
      users
    end

    protected

    def initialize; @list = Array.new; end
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

    def initialize(id,is_admin,username,email)
      @id = id
      @is_admin = is_admin
      @username = username
      @email = email
    end

    # Returns true if this user is an admin of the account in which they live
    def is_admin?
      @is_admin
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

    protected

    def initialize(message,http_status)
      @message = message
      @http_status = http_status
    end

  end
end
