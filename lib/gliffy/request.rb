require 'rubygems'
require 'httparty'
require 'logger'
require 'gliffy/url'

module Gliffy
  # Handles making a request of the Gliffy server and all that that entails.
  class Request

    attr_accessor :logger
    # Modify the HTTP transport agent used.  This should
    # have the same interface as HTTParty.
    attr_accessor :http

    def initialize(api_root,credentials,http=HTTParty,logger=nil)
      @api_root = api_root
      @api_root += '/' if !(@api_root =~ /\/$/)
      @credentials = credentials
      @logger = logger || Logger.new(STDOUT)
      @logger.level = Logger::INFO
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
        @full_url_no_params = @api_root + replace_url(args[0])
        url = SignedURL.new(@credentials,@full_url_no_params,'POST')
        url.params = args[1] if !args[1].nil?
        url[:action] = symbol

        # These can be override for testing purposes
        timestamp = args[2] if args[2]
        nonce = args[3] if args[3]

        response = @http.post(url.full_url(timestamp,nonce))
        return response
      else
        super(symbol,@args)
      end
    end

    def replace_url(url)
      return url.gsub('$account_id',@credentials.account_id.to_s).gsub('$username',@credentials.username)
    end
  end
end
