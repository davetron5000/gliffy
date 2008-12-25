require 'rexml/document'
include REXML

module Gliffy

  # Parses the Gliffy XML format
  class XML
    def self.parse(xml)
      root = Document.new(xml).root
      GliffyResponse.new(root)
    end
  end

  class GliffyResponse
    attr_reader :not_modified
    attr_reader :success
    attr_reader :element

    def initialize(xml_root)
      @not_modified = xml_root.attributes['not-modified']
      @success = xml_root.attributes['success'] == "true"
      clazz = Kernel.const_get("Gliffy" + to_classname(xml_root.elements[1].name))
      @element = clazz.new(xml_root.elements[1]);
    end

    private

    def to_classname(name)
      classname = ""
      name.split(/-/).each do |part|
        classname += part.capitalize
      end
      classname
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

  class GliffyUsers

    def initialize(element)
      @users = Array.new
      element.each_element do |element|
        @users << GliffyUser.new(element)
      end
    end

    def [](index)
      @users[index]
    end

    def length
      @users.length
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
