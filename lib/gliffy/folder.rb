require 'rexml/document'
require 'array_has_response'
require 'gliffy/rest'

include REXML

module Gliffy

  class Folders < ArrayResponseParser; end

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

    # Encodes the elements of a folder path so it can safely go into a URL
    def self.encode_path_elements(folder_path)
      encoded = ''
      folder_path.split(/\//).each do |part|
        encoded += CGI::escape(part)
        encoded += "/"
      end
      encoded.gsub(/\/$/,'')
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
end
