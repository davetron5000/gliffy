require 'gliffy/request'

module Gliffy
  # Indicates no response at all was received.
  class NoResponseException < Exception
    def initialize(message)
      super(message)
    end
  end
  # Indicates that a response was received by that it wasn't
  # parsable or readable as a Gliffy <response> 
  class BadResponseException < Exception
    def initialize(message)
      super(message)
    end
  end
  # Indicates that a valid Gliffy <response> was received and that it 
  # indicated failure.  The message is the message sent by gliffy (if it was
  # in the response)
  class RequestFailedException < Exception
    def initialize(message)
      super(message)
    end
  end

  class BadAuthorizationException < Exception
    def initialize(message)
      super(message)
    end
  end
  # Base class for all response from gliffy
  class Response
    @@normal_error_callback = Proc.new do |response,exception|
      if response
        message = response.inspect
        if response['response'] && response['response']['error']
          http_status = response['response']['error']['http_status']
          # It seems that HTTParty is not able to figure out the http-status when the contents of
          # the tag is text.  Weird.  This hack seems to work reasonably well.
          if !http_status
            http_status = response.body.gsub(/^.*http-status=\"/,'').gsub(/\".*$/,'')
          end
          if http_status == '404'
            message = 'Not Found'
          elsif http_status == '401'
            raise BadAuthorizationException.new(response['response']['error'])
          else
            message = "HTTP Status #{http_status} : #{response['response']['error']}"
          end
        end
        raise exception.class.new(message)
      else
        raise exception 
      end
    end

    @@error_callback = @@normal_error_callback

    # Factory for creating actual response subclasses.
    # This takes the results of HTTParty's response, which is a hash, essentially.
    # This assumes that any checks for validity have been done.
    # [error_response] Set this to a Proc to handle errors if you don't want the default behavior.  The proc will get two arguments:
    #                  [+response+] the raw response received (may be nil)
    #                  [+exception+] One of NoResponseException, BadResponseException, or RequestFailedException.  The message of that exception is a usable message if you want to ignore the exception
    def self.from_http_response(response,error_callback=nil)
      verify(response,error_callback)
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

    # Verifies that the response represents success, calling
    # the error callback if it doesn't
    def self.verify(response,error_callback)
      error_callback = @@error_callback if error_callback.nil?
      return error_callback.call(response,NoResponseException.new('No response received at all')) if response.nil? 
      return error_callback.call(response,BadResponseException.new('Not a Gliffy response')) if !response['response']
      return error_callback.call(response,BadResponseException.new('No indication of success from Gliffy')) if !response['response']['success']
      if response['response']['success'] != 'true'
        error = response['response']['error']
        return error_callback.call(response,RequestFailedException.new('Request failed but no error inside response')) if !error
        return error_callback.call(response,RequestFailedException.new(error))
      end
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

  class ArrayParser # :nodoc:
    def self.from_http_response(root,single_class,plural_name,single_name)
      root = root[plural_name]
      return nil if root.nil?
      if root[single_name].kind_of?(Array)
        list = Array.new
        root[single_name].each do |item|
          list << single_class.from_http_response(item)
        end
        list
      else
        [single_class.from_http_response(root[single_name])]
      end
    end
  end

  # Factory for parsing accounts
  class AccountsParser # :nodoc:
    def self.from_http_response(root)
      return ArrayParser.from_http_response(root,AccountParser,'accounts','account')
    end
  end

  # Factory for parsing folders
  class FoldersParser # :nodoc:
    def self.from_http_response(root)
      return ArrayParser.from_http_response(root,FolderParser,'folders','folder')
    end
  end

  # Factory for parsing versions
  class VersionsParser # :nodoc:
    def self.from_http_response(root)
      return ArrayParser.from_http_response(root,VersionParser,'versions','version')
    end
  end

  # Factory for parsing users
  class UsersParser # :nodoc:
    def self.from_http_response(root)
      return ArrayParser.from_http_response(root,UserParser,'users','user')
    end
  end

  # Factory for parsing documents
  class DocumentsParser # :nodoc:
    def self.from_http_response(root)
      return ArrayParser.from_http_response(root,DocumentParser,'documents','document')
    end
  end

  class BaseParser # :nodoc:
    def self.from_http_response(root)
      params = Hash.new
      root.each do |key,value|
        params[key.to_sym] = value
      end
      Response.new(params)
    end

    # Returns the item as an array, or nil if it was nil
    def self.as_array(item)
      if item.nil?
        nil
      else
        [item].flatten
      end
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

  class FolderParser < BaseParser # :nodoc:
    def self.from_http_response(root)
      add_int(root,'id','folder_id')
      add_boolean(root,'is_default')
      if root['folder']
        if root['folder'].kind_of? Array
          root['child_folders'] = Array.new
          root['folder'].each do |one|
            root['child_folders'] << from_http_response(one)
          end
        else
          root['child_folders'] = [from_http_response(root['folder'])]
        end
      else
        root['child_folders'] = Array.new
      end
      super(root)
    end
  end

  class UserParser < BaseParser # :nodoc:
    def self.from_http_response(root)
      add_int(root,'id','user_id')
      add_boolean(root,'is_admin')
      super(root)
    end
  end

  # Parses the results from the test account request
  class TestaccountParser < BaseParser # :nodoc:
    def self.from_http_response(root)
      root = root['testAccount']
      add_int(root,'id','account_id')
      add_int(root,'max_users')
      add_boolean(root,'terms')
      add_date(root,'expiration_date')
      super(root)
    end
  end

  # Factory for parsing an Account
  class AccountParser < BaseParser # :nodoc:
    def self.from_http_response(root)
      add_int(root,'id','account_id')
      add_int(root,'max_users')
      add_boolean(root,'terms')
      add_date(root,'expiration_date')
      root['users'] = as_array(UsersParser.from_http_response(root))
      super(root)
    end
  end

  # Factory for parsing an Account
  class DocumentParser < BaseParser # :nodoc:
    def self.from_http_response(root)
      add_int(root,'id','document_id')
      add_int(root,'num_versions')
      add_boolean(root,'is_private')
      add_boolean(root,'is_public')
      add_date(root,'create_date')
      add_date(root,'mod_date')
      add_date(root,'published_date')
      root['owner'] = UserParser.from_http_response(root['owner'])
      root['versions'] = as_array(VersionsParser.from_http_response(root))
      super(root)
    end
  end

  class VersionParser < BaseParser # :nodoc:
    def self.from_http_response(root)
      add_int(root,'id','version_id')
      add_int(root,'num')
      add_date(root,'create_date')
      root['owner'] = UserParser.from_http_response(root['owner'])
      super(root)
    end
  end

  class OauthTokenCredentialsParser # :nodoc:
    def self.from_http_response(root)
      token = root['oauth_token_credentials']['oauth_token']
      secret = root['oauth_token_credentials']['oauth_token_secret']
      return AccessToken.new(token,secret)
    end
  end

end
