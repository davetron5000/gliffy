require 'rexml/document'
include REXML

module Gliffy


  class GliffyResponse
    # Returns true if this response represents a "not-modified"
    # response, which means that the requested resource can be safely
    # fetched from the cache
    attr_reader :not_modified

    # Returns true if the response represents a successful response
    # false indicates failure and that element is most likely a GliffyError
    attr_reader :success
    attr_reader :element

    # Creates a GliffyResponse based on the XML passed in.
    # The xml can be anything passable to REXML::Document.new, such as
    # a Document, or a string containing XML
    def self.parse(xml)
      root = Document.new(xml).root
      GliffyResponse.new(root)
    end

    private

    def initialize(xml_root)
      @not_modified = xml_root.attributes['not-modified']
      @success = xml_root.attributes['success'] == "true"
      clazz = Kernel.const_get("Gliffy" + to_classname(xml_root.elements[1].name))
      @element = clazz.new(xml_root.elements[1]);
    end


    def to_classname(name)
      classname = ""
      name.split(/-/).each do |part|
        classname += part.capitalize
      end
      classname
    end
  end

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

  class GliffyAccount

    attr_reader :name
    attr_reader :id
    attr_reader :type
    attr_reader :max_users
    attr_reader :expiration_date
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
      @expiration_date = Time.at(element.elements['expiration-date'].text.to_i)
      @name = element.elements['name'].text
      if element.elements['users']
        @users = GliffyUsers.new(element.elements['users'])
      else
        @users = Array.new
      end
    end
  end

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

  class GliffyDiagram

    attr_reader :id
    attr_reader :num_versions
    attr_reader :create_date
    attr_reader :mod_date
    attr_reader :name
    attr_reader :owner_username
    attr_reader :published_date

    def initialize(element)
      @id = element.attributes['id'].to_i
      @num_versions = element.attributes['num-versions'].to_i
      @is_private = element.attributes['is-private'] == "true"
      @is_public = element.attributes['is-public'] == "true"

      @create_date = Time.at(element.elements['create-date'].text.to_i)
      @mod_date = Time.at(element.elements['mod-date'].text.to_i)
      @published_date = element.elements['published-date'] ? Time.at(element.elements['published-date'].text.to_i) : nil
      @name = element.elements['name'].text
      @owner_username = element.elements['owner'] ? element.elements['owner'].text : nil
    end

    def is_public?
      @is_public
    end

    def is_private?
      @is_private
    end
  end

  class GliffyLaunchLink

    attr_reader :diagram_name
    attr_reader :url

    def initialize(element)
      @diagram_name = element.attributes['diagram-name']
      @url = element.text
    end
  end

  class GliffyUserToken
    attr_reader :expiration
    attr_reader :token
    def initialize(element)
      @expiration = Time.at(element.attributes['expiration'].to_i)
      @token = element.text
    end
  end

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

    attr_reader :folders
    attr_reader :id
    attr_reader :name
    attr_reader :path

    def initialize(element)
      @id = element.attributes['id'].to_i
      @default = element.attributes['is-default'] == "true"
      @name = element.elements['name'].text
      @path = element.elements['path'].text
      @folders = Array.new
      element.each_element do |element|
        @folders << GliffyFolder.new(element) if element.name == "folder"
      end
    end

    def default?
      @default
    end
  end

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

  class GliffyUser
    attr_reader :username
    attr_reader :email
    attr_reader :id
    def initialize(element)
      @id = element.attributes['id'].to_i
      @is_admin = false
      @is_admin = element.attributes['is-admin'] == 'true' if element.attributes['is-admin'] 
      @username = element.elements['username'] ? element.elements['username'].text : nil
      @email = element.elements['email'] ? element.elements['email'].text : nil
    end

    def is_admin?
      @is_admin
    end
  end

  class GliffyError
    attr_reader :http_status
    attr_reader :message

    def initialize(element)
      @message = element.text
      @http_status = element.attributes['http-status'].to_i
    end

  end
end
