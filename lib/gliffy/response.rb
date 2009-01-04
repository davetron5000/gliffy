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
    attr_accessor :rest

    protected

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

    def to_s
      "#{@http_status}: #{@message}"
    end

  end
end
