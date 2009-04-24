require 'rubygems'
require 'httparty'
require 'logger'
require 'gliffy/url'

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
  # Handles making a request of the Gliffy server and all that that entails.
  # This allows you to make requests using the "action" and the URL as
  # described in the Gliffy documentation.  For example, if you wish 
  # to get a user's folders, you could
  #
  #     request = Request.net('https://www.gliffy.com/api/1.0',credentials)
  #     results = request.create('accounts/$account_id/users/$username/oauth_token.xml')
  #     credentials.update_access_token(
  #         results['response']['oauth_token_credentials']['oauth_token_secret'],
  #         results['response']['oauth_token_credentials']['oauth_token'])
  #     request.get('accounts/$account_id/users/$username/folders.xml')
  #
  # This will return a hash-referencable DOM objects, subbing the account id
  # and username in when making the request (additionally, setting all needed
  # parameters and signing the request).
  #
  # This will also do a limited analysis of the response to determine if it is in
  # error.  Since, under normal conditions, you should not get error responses from Gliffy
  # this class, by default, will throw an exception when any error occurs.  You can
  # override this behavior by setting an error_callback.
  class Request

    attr_accessor :logger
    # Modify the HTTP transport agent used.  This should
    # have the same interface as HTTParty.
    attr_accessor :http

    # Set this to a Proc to handle errors if you don't want the default
    # behavior.  The proc will get two arguments:
    # [+response+] the raw response received (may be nil)
    # [+exception+] One of NoResponseException, BadResponseException, or RequestFailedException.  The 
    # message of that exception is a usable message if you want to ignore the exception
    attr_writer :error_callback

    # Create a new request object.
    #
    # [+api_root+] the root of where all API calls are made
    # [+credentials+] a Credentials object with all the current credentials
    # [+http+] This should implement the HTTParty interface
    def initialize(api_root,credentials,http=HTTParty,logger=nil)
      @api_root = api_root
      @api_root += '/' if !(@api_root =~ /\/$/)
      @credentials = credentials
      @logger = logger || Logger.new(STDOUT)
      @logger.level = Logger::INFO
      @error_callback = Proc.new do |response,exception| 
        raise exception
      end
    end

    # Implements getting a request and returning a response
    # The implements methods that correspond to Gliffy's "action=" parameter.
    # Based on this, it will know to do a GET or POST.  The method signature is
    #
    #     request.action_name(url,params)
    # for example
    #     request.get('accounts/$account_id.xml',:showUsers => true)
    # note that you can use `$account_id` and `$username` in any URL and it 
    # will be replaced accordingly.
    #
    # The return value is the return value from HTTPart, which is basically a hash
    # that allows access to the returned DOM tree
    def method_missing(symbol,*args)
      if args.length >= 1
        @logger.debug("Executing a #{symbol} against gliffy for url #{args[0]}")

        # exposing this for testing
        protocol = determine_protocol(args[1])
        @full_url_no_params = protocol + "://" + @api_root + replace_url(args[0])
        url = SignedURL.new(@credentials,@full_url_no_params,'POST')
        url.logger = @logger
        url.params = args[1] if !args[1].nil?
        url[:protocol_override] = nil
        url[:action] = symbol

        # These can be override for testing purposes
        timestamp = args[2] if args[2]
        nonce = args[3] if args[3]

        response = @http.post(url.full_url(timestamp,nonce))
        verify(response)
        return response
      else
        super(symbol,@args)
      end
    end

    def determine_protocol(params)
      if params && params[:protocol_override]
        params[:protocol_override].to_s
      else
        @credentials.default_protocol.to_s
      end
    end

    def replace_url(url)
      return url.gsub('$account_id',@credentials.account_id.to_s).gsub('$username',@credentials.username)
    end

    private 
    # Verifies that the response represents success, calling
    # the error callback if it doesn't
    def verify(response)
      return @error_callback.call(response,NoResponseException.new('No response received at all')) if response.nil? 
      return @error_callback.call(response,BadResponseException.new('Not a Gliffy response')) if !response['response']
      return @error_callback.call(response,BadResponseException.new('No indication of success from Gliffy')) if !response['response']['success']
      if response['response']['success'] != 'true'
        error = response['response']['error']
        return @error_callback.call(response,RequestFailedException.new('Request failed but no error inside response')) if !error
        return @error_callback.call(response,RequestFailedException.new(error))
      end
    end
  end
end
