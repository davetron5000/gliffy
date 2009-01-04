require 'rexml/document'
require 'array_has_response'
require 'gliffy/rest'

include REXML

module Gliffy

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

  class Diagrams < ArrayResponseParser; end
end
