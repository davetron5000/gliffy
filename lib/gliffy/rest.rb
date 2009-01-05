require 'digest/md5'
require 'cgi'
require 'rubygems'
require 'request_errors'
require 'resource'
require 'rest_client'

require 'gliffy/config'
require 'gliffy/url'

require 'logger'

module Gliffy

  # Provides REST access to Gliffy, handling the signing of the requests
  # but not the parsing of the results.  This class responds to the four primary HTTP methods:
  #
  # * get
  # * put
  # * post
  # * delete
  #
  # Each method takes three parameters:
  # [url] - the relative URL being requested
  # [params] - a hash of parameters to include in the request (these are specific to the request, not things like apiKey or token)
  # [headers] - any HTTP headers you want to set
  #
  # params and headers are optional.  These methods return whatever Gliffy sent back.  The context
  # of the request should be used to determine the type, however it should be relatively safe to call
  # Response#success? on whatever is returned to determine if everythign was OK
  #
  class Rest

    # Provides access to the current token, 
    # returning nil if none has been set
    attr_accessor :current_token

    # Provides access to the logger
    # Do not set this to nil
    attr_accessor :logger

    attr_accessor :rest_client

    # Create an accessor to the Gliffy REST api
    #
    def initialize
      @current_token = nil
      self.rest_client=RestClient
      @logger = Logger.new(Config.config.log_device)
      @logger.level = Config.config.log_level

      @logger.debug("Creating #{self.class.to_s} with api_key of #{Config.config.api_key} against #{Config.config.gliffy_root}")
    end

    # Returns the complete URL that would be requested for
    # the given URL and parameters
    #
    # [url] the URL, relative to the Gliffy API Root
    # [params] a hash of parameters
    #
    def get_url(url,params=nil)
      return create_url(url,params)
    end

    # Implements the http methods
    def method_missing(symbol,*args)
      if HTTP_METHODS[symbol]  && (args.length > 0)
        url,params,headers = args
        make_rest_request(symbol,url,params,headers)
      else
        if (HTTP_METHODS[symbol])
          raise ArgumentError.new("Wrong number of arguments for method #{symbol.to_s}") 
        else
          super.method_missing(symbol,*args)
        end
      end
    end

    # Create the URL that would be needed to access the given resource with the given
    # parameters
    #
    #   [+url+] url, relative to the gliffy root, to retrieve
    #   [+params+] optional hash of parameters
    #
    def create_url(url,params=nil)
      url = SignedURL.new(Config.config.api_key,Config.config.secret_key,Config.config.gliffy_root,url)
      url.params=params if params
      url['token'] = @current_token.token if @current_token

      url.full_url
    end

    protected

    def make_rest_request(method,url,params,headers)
      headers = Hash.new if !headers
      request_url = create_url(url,params)
      @logger.debug("#{method.to_s.upcase} #{request_url}")
      @rest_client.send(method,request_url,headers)
    end

    HTTP_METHODS = {
      :get => true,
      :put => true,
      :delete => true,
      :post => true,
    };

  end
end
