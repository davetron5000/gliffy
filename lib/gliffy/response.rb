require 'rexml/document'
include REXML

module Gliffy

  class ActiveGliffyObject
    # A GliffyHandle 
    attr_accessor :handle
  end

  # Encapsulates a response from Gliffy.  The element accessor provides
  # access to the actual element in question.  The class method
  # of element can provide you information as to what the response is
  # (though it should be known from context).  Instances can
  # be obtained via the parse method.
  class Response
    # Returns true if this response represents a "not-modified"
    # response, which means that the requested resource can be safely
    # fetched from the cache
    attr_reader :not_modified

    attr_reader :element

    # Creates a Response based on the XML passed in.
    # The xml can be anything passable to REXML::Document.new, such as
    # a Document, or a string containing XML
    def self.parse(xml)
      root = Document.new(xml).root
      Response.new(root)
    end

    # Returns true if the response represents a successful response
    # false indicates failure and that element is most likely a Error
    def success?
      @success
    end

    private

    def initialize(xml_root)
      @not_modified = xml_root.attributes['not-modified']
      @success = xml_root.attributes['success'] == "true"
      if ! xml_root.elements.empty?
        clazz = Gliffy.const_get(to_classname(xml_root.elements[1].name))
        @element = clazz.new(xml_root.elements[1]);
      end
    end

    # Converts a dash-delimited string to a camel-cased classname
    def to_classname(name)
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

    def [](index)
      @list[index]
    end

    def length
      @list.length
    end
  end

  # Represents a list of Account objects
  class Accounts

    include Enumerable
    include ContainerArray

    def initialize(element)
      @list = Array.new
      element.each_element do |element|
        @list << Account.new(element)
      end
    end
  end

  # Represents on account
  class Account < ActiveGliffyObject

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

    def initialize(element)
      @id = element.attributes['id'].to_i
      type = element.attributes['account-type']
      if type == 'Basic'
        @type = :basic
      elsif type == 'Premium'
        @type = :premium
      else
        raise "Unknown type #{type}"
      end
      @max_users = element.attributes['max-users'].to_i
      @expiration_date = Time.at(element.elements['expiration-date'].text.to_i / 1000)
      @name = element.elements['name'].text
      if element.elements['users']
        @users = Users.new(element.elements['users'])
      else
        @users = Array.new
      end
    end

    # Returns the users of this account
    def all_users
      users = @handle.get(@handle.url_for('users'))
      users.element.each() { |user| user.handle = @handle }
      users.element
    end

    def all_folders
      folders = @handle.get(@handle.url_for('folders'))
      folders.element.each() { |folder| folder.handle = @handle }
      folders.element
    end

    def all_diagrams
      diagrams = @handle.get(@handle.url_for('diagrams'))
      diagrams.element.each() { |diagram| diagram.handle = @handle }
      diagrams.element
    end

  end

  # A list of Diagram objects
  class Diagrams

    include Enumerable
    include ContainerArray

    def initialize(element)
      @list = Array.new
      element.each_element do |element|
        @list << Diagram.new(element)
      end
    end
  end

  # A gliffy diagram (or, rather, the meta data about that diagram)
  class Diagram < ActiveGliffyObject

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

    def initialize(element)
      @id = element.attributes['id'].to_i
      @num_versions = element.attributes['num-versions'].to_i
      @is_private = element.attributes['is-private'] == "true"
      @is_public = element.attributes['is-public'] == "true"

      @create_date = Time.at(element.elements['create-date'].text.to_i / 1000)
      @mod_date = Time.at(element.elements['mod-date'].text.to_i / 1000)
      @published_date = element.elements['published-date'] ? Time.at(element.elements['published-date'].text.to_i / 1000) : nil
      @name = element.elements['name'].text
      @owner_username = element.elements['owner'] ? element.elements['owner'].text : nil
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
  class LaunchLink

    # The name of the diagram, which can helpful
    # in creating HTML hyperlinks to url
    attr_reader :diagram_name
    attr_reader :url

    def initialize(element)
      @diagram_name = element.attributes['diagram-name']
      @url = element.text
    end
  end

  # A user token
  class UserToken
    attr_reader :expiration
    attr_reader :token
    def initialize(element)
      @expiration = Time.at(element.attributes['expiration'].to_i / 1000)
      @token = element.text
    end
  end

  # A list of folders.  Note that this only
  # represents the top level access to the folders
  # (see Folder below)
  class Folders

    include Enumerable
    include ContainerArray

    def initialize(element)
      @list = Array.new
      element.each_element do |element|
        @list << Folder.new(element)
      end
    end

  end

  class Folder < ActiveGliffyObject

    # An array of Folder objects that are contained within this folder
    # If this is empty, it means this Folder is a leaf
    attr_reader :child_folders
    attr_reader :id
    attr_reader :name
    # The full path to this folder within the account's 
    # folder hierarchy
    attr_reader :path

    def initialize(element)
      @id = element.attributes['id'].to_i
      @default = element.attributes['is-default'] == "true"
      @name = element.elements['name'].text
      @path = element.elements['path'].text
      @child_folders = Array.new
      element.each_element do |element|
        @child_folders << Folder.new(element) if element.name == "folder"
      end
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
  class Users

    include Enumerable
    include ContainerArray

    def initialize(element)
      @list = Array.new
      element.each_element do |element|
        @list << User.new(element)
      end
    end
  end

  # A user of Gliffy
  class User < ActiveGliffyObject

    # The user's username, which is their identifier within an account
    attr_reader :username
    # The user's email, which is unique to them in the entire Gliffy system.
    # Note that this isn't guaranteed to be a real email, nor is
    # it guaranteed to be the user's actual email.  This is 
    # assigned by the system unless overridden by the API.
    attr_reader :email
    attr_reader :id

    def initialize(element)
      @id = element.attributes['id'].to_i
      @is_admin = false
      @is_admin = element.attributes['is-admin'] == 'true' if element.attributes['is-admin'] 
      @username = element.elements['username'] ? element.elements['username'].text : nil
      @email = element.elements['email'] ? element.elements['email'].text : nil
    end

    # Returns true if this user is an admin of the account in which they live
    def is_admin?
      @is_admin
    end

  end

  # An error from Gliffy
  class Error
    # The HTTP status code that can help indicate the nature of the problem
    attr_reader :http_status
    # A description of the error that occured; not necessarily for human
    # consumption
    attr_reader :message

    def initialize(element)
      @message = element.text
      @http_status = element.attributes['http-status'].to_i
    end

  end
end
