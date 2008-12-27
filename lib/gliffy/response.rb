require 'rexml/document'
include REXML

module Gliffy


  # Encapsulates a response from Gliffy.  The element accessor provides
  # access to the actual element in question.  The class method
  # of element can provide you information as to what the response is
  # (though it should be known from context).  Instances can
  # be obtained via the parse method.
  class GliffyResponse
    # Returns true if this response represents a "not-modified"
    # response, which means that the requested resource can be safely
    # fetched from the cache
    attr_reader :not_modified

    attr_reader :element

    # Creates a GliffyResponse based on the XML passed in.
    # The xml can be anything passable to REXML::Document.new, such as
    # a Document, or a string containing XML
    def self.parse(xml)
      root = Document.new(xml).root
      GliffyResponse.new(root)
    end

    # Returns true if the response represents a successful response
    # false indicates failure and that element is most likely a GliffyError
    def success?
      @success
    end

    private

    def initialize(xml_root)
      @not_modified = xml_root.attributes['not-modified']
      @success = xml_root.attributes['success'] == "true"
      clazz = Gliffy.const_get("Gliffy" + to_classname(xml_root.elements[1].name))
      @element = clazz.new(xml_root.elements[1]);
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
      @list.each { |list| yield account }
    end

    def [](index)
      @list[index]
    end

    def length
      @list.length
    end
  end

  # Represents a list of accounts
  class GliffyAccounts

    include Enumerable
    include ContainerArray

    def initialize(element)
      @list = Array.new
      element.each_element do |element|
        @list << GliffyAccount.new(element)
      end
    end
  end

  # Represents on account
  class GliffyAccount

    attr_reader :name
    attr_reader :id
    # Either :basic or :premium
    attr_reader :type
    attr_reader :max_users
    # A Time representing the date on which this account expires
    attr_reader :expiration_date
    # Returns a GliffyUsers representing the users that
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
        @users = GliffyUsers.new(element.elements['users'])
      else
        @users = Array.new
      end
    end
  end

  # A list of Gliffy diagrams
  class GliffyDiagrams

    include Enumerable
    include ContainerArray

    def initialize(element)
      @list = Array.new
      element.each_element do |element|
        @list << GliffyDiagram.new(element)
      end
    end
  end

  # A gliffy diagram (or, rather, the meta data about that diagram)
  class GliffyDiagram

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
  class GliffyLaunchLink

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
  class GliffyUserToken
    attr_reader :expiration
    attr_reader :token
    def initialize(element)
      @expiration = Time.at(element.attributes['expiration'].to_i / 1000)
      @token = element.text
    end
  end

  # A list of folders.  Note that this only
  # represents the top level access to the folders
  # (see GliffyFolder below)
  class GliffyFolders

    include Enumerable
    include ContainerArray

    def initialize(element)
      @list = Array.new
      element.each_element do |element|
        @list << GliffyFolder.new(element)
      end
    end
  end

  class GliffyFolder

    # An array of GliffyFolder objects that are contained within this folder
    # If this is empty, it means this GliffyFolder is a leaf
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
        @child_folders << GliffyFolder.new(element) if element.name == "folder"
      end
    end

    # Returns true if this folder is the default folder
    # used when an operation requiring a folder
    # doesn't specify one (such as when creating a new
    # diagram)
    def default?
      @default
    end
  end

  # A list of users
  class GliffyUsers

    include Enumerable
    include ContainerArray

    def initialize(element)
      @list = Array.new
      element.each_element do |element|
        @list << GliffyUser.new(element)
      end
    end
  end

  # A user of Gliffy
  class GliffyUser

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
  class GliffyError
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
