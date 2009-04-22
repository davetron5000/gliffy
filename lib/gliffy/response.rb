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

  # Factory for parsing accounts
  class AccountsParser
    def self.from_http_response(root)
      root = root['accounts']
      if root['account'].kind_of? Array
        accounts = Array.new
        root['account'].each do |account|
          accounts << AccountParser.from_http_response(account)
        end
        accounts
      else
        AccountParser.from_http_response(root['account'])
      end
    end
  end

  # Factory for parsing an Account
  class AccountParser
    def self.from_http_response(root)
      root['account_id'] = root['id'].to_i
      root['max_users'] = root['max_users'].to_i
      root['terms'] = root['terms'] == 'true'
      root['expiration_date'] = Time.at(root['expiration_date'].to_i / 1000)
      params = Hash.new
      root.each do |key,value|
        params[key.to_sym] = value
      end
      Response.new(params)
    end
  end
end
