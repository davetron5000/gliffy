require 'gliffy/request'

module Gliffy
  # Base class for all response from gliffy
  class Response
    # Factory for creating actual response subclasses.
    # This takes the results of HTTParty's response, which is a hash, essentially.
    # This assumes that any checks for validity have been done.
    def self.from_http_response(response)
      root = response['response']
      klass = nil
      root.keys.each do |key|
        klassname = to_classname(key)
        begin
          this_klass = Gliffy.const_get(klassname)
        rescue NameError
          this_klass = nil
        end
        klass = this_klass unless this_klass.nil?
      end
      return Response.new(response.body) if !klass
      return klass.from_http_response(root)
    end

    attr_reader :body
    
    def initialize(params)
      @params = params
    end

    # Implements access to the object information.
    # Parameters should be typed appropriately.
    # The names are those as defined by the Gliffy XSD, save for dashes
    # are replaced with underscores.
    def method_missing(symbol,*args)
      if args.length == 0
        @params[symbol]
      else
        super(symbol,args)
      end
    end

    private 
    def self.to_classname(name)
      classname = ""
      name.split(/[-_]/).each do |part|
        classname += part.capitalize
      end
      classname + "Parser"
    end
  end

  class ArrayParser
    def self.from_http_response(root,single_class,plural_name,single_name)
      root = root[plural_name]
      return nil if root.nil?
      if root[single_name].kind_of? Array
        list = Array.new
        root[single_name].each do |item|
          list << single_class.from_http_response(item)
        end
        list
      else
        single_class.from_http_response(root[single_name])
      end
    end
  end

  # Factory for parsing accounts
  class AccountsParser
    def self.from_http_response(root)
      return ArrayParser.from_http_response(root,AccountParser,'accounts','account')
    end
  end

  # Factory for parsing accounts
  class VersionsParser
    def self.from_http_response(root)
      return ArrayParser.from_http_response(root,VersionParser,'versions','version')
    end
  end

  # Factory for parsing users
  class UsersParser
    def self.from_http_response(root)
      return ArrayParser.from_http_response(root,UserParser,'users','user')
    end
  end
  
  # Factory for parsing documents
  class DocumentsParser
    def self.from_http_response(root)
      return ArrayParser.from_http_response(root,DocumentParser,'documents','document')
    end
  end
  
  class BaseParser
    def self.from_http_response(root)
      params = Hash.new
      root.each do |key,value|
        params[key.to_sym] = value
      end
      Response.new(params)
    end

    def self.add_int(root,name,new_name=nil)
      if root[name]
        root[new_name.nil? ? name : new_name] = root[name].to_i
      end
    end

    def self.add_boolean(root,name)
      root[name + "?"] = root[name] == 'true'
    end

    def self.add_date(root,name)
      if root[name]
        root[name] = Time.at(root[name].to_i / 1000) unless root[name].kind_of? Time
      end
    end
  end

  class UserParser < BaseParser
    def self.from_http_response(root)
      add_int(root,'id','user_id')
      add_boolean(root,'is_admin')
      super(root)
    end
  end

  # Factory for parsing an Account
  class AccountParser < BaseParser
    def self.from_http_response(root)
      add_int(root,'id','account_id')
      add_int(root,'max_users')
      add_boolean(root,'terms')
      add_date(root,'expiration_date')
      root['users'] = UsersParser.from_http_response(root)
      super(root)
    end
  end

  # Factory for parsing an Account
  class DocumentParser < BaseParser
    def self.from_http_response(root)
      add_int(root,'id','document_id')
      add_int(root,'num_versions')
      add_boolean(root,'is_private')
      add_boolean(root,'is_public')
      add_date(root,'create_date')
      add_date(root,'mod_date')
      add_date(root,'published_date')
      root['owner'] = UserParser.from_http_response(root['owner'])
      root['versions'] = VersionsParser.from_http_response(root)
      super(root)
    end
  end

  class VersionParser < BaseParser
    def self.from_http_response(root)
      add_int(root,'id','version_id')
      add_int(root,'num')
      add_date(root,'create_date')
      root['owner'] = UserParser.from_http_response(root['owner'])
      super(root)
    end
  end

end
