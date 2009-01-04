require 'digest/md5'
require 'cgi'
require 'rubygems'
require 'request_errors'
require 'resource'
require 'rest_client'

require 'gliffy/response'
require 'gliffy/config'
require 'gliffy/url'

require 'logger'

module Gliffy

  # Provides REST access to Gliffy, handling the signing of the requests
  # and parsing of the results.  This class responds to the four primary HTTP methods:
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
  # params and headers are optional.
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
      @api_key = Config.api_key
      @secret_key = Config.secret_key
      @gliffy_root = Config.gliffy_root
      @current_token = nil
      self.rest_client=RestClient
      @logger = Logger.new(Config.log_device)
      @logger.level = Config.log_level

      @logger.debug("Creating #{self.class.to_s} with api_key of #{@api_key} against #{@gliffy_root}")
    end

    # Gets the resource without attempting to parse.  This is useful if the expected
    # representation type is not the Gliffy XML format
    def get_raw(url,params=nil,headers={})
      request_url = create_url(url,params)
      @logger.debug("GET #{request_url}")
      @rest_client.get(request_url,headers)
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

    protected

    def make_rest_request(method,url,params,headers)
      headers = Hash.new if !headers
      request_url = create_url(url,params)
      @logger.debug("#{method.to_s.upcase} #{request_url}")
      xml = @rest_client.send(method,request_url,headers)
      response = Response.from_xml(xml)
      return response
    end

    HTTP_METHODS = {
      :get => true,
      :put => true,
      :delete => true,
      :post => true,
    };


    def create_url(url,params)
      url = SignedURL.new(@api_key,@secret_key,@gliffy_root,url)
      url.params=params if params
      url['token'] = @current_token if @current_token

      url.full_url
    end
  end
end
