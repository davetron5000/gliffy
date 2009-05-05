require 'rubygems'
require 'httparty'
require 'logger'
require 'gliffy/url'

module Gliffy
  # Handles making a request of the Gliffy server and all that that entails.
  # This allows you to make requests using the "action" and the URL as
  # described in the Gliffy documentation.  For example, if you wish 
  # to get a user's folders, you could
  #
  #     request = Request.get('https://www.gliffy.com/api/1.0',credentials)
  #     results = request.create('accounts/$account_id/users/$username/oauth_token.xml')
  #     credentials.update_access_token(
  #         results['response']['oauth_token_credentials']['oauth_token_secret'],
  #         results['response']['oauth_token_credentials']['oauth_token'])
  #     request.get('accounts/$account_id/users/$username/folders.xml')
  #
  # This will return a hash-referencable DOM objects, subbing the account id
  # and username in when making the request (additionally, setting all needed
  # parameters and signing the request).
  class Request

    attr_accessor :logger
    # Modify the HTTP transport agent used.  This should
    # have the same interface as HTTParty.
    attr_accessor :http

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
      @http = http
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
    # The return value is the return value from HTTParty, which is basically a hash
    # that allows access to the returned DOM tree
    def method_missing(symbol,*args)
      if args.length >= 1
        link_only = false
        if symbol == :link_for
          symbol = args.shift
          link_only = true
        end
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

        full_url = url.full_url(timestamp,nonce)
        if link_only
          return full_url
        else
          response = @http.post(full_url)
          return response
        end
      else
        super(symbol,args)
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
  end
end
