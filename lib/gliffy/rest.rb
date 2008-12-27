require 'digest/md5'
require 'cgi'
require 'rubygems'
require 'request_errors'
require 'resource'
require 'rest_client'
require 'gliffy/response.rb'
require 'logger'

module Gliffy

  # Provides REST access to Gliffy, handling the signing of the requests
  # and parsing of the results
  class Rest

    # Provides access to the current token, 
    # returning nil if none has been set
    attr_accessor :current_token

    # Create an accessor to the Gliffy REST api
    #
    # [api_key] your Gliffy API key
    # [secret_key] the shared secret for signing requests
    # [gliffy_root] root URL of the Gliffy API
    #
    def initialize(api_key,secret_key,gliffy_root = 'http://www.gliffy.com/gliffy/rest')
      @api_key = api_key
      @secret_key = secret_key
      @gliffy_root = gliffy_root
      @current_token = nil
      @logger = Logger.new(STDERR)
      @logger.level = Logger::DEBUG

      @logger.debug("Creating #{self.class.to_s} with api_key of #{api_key} against #{gliffy_root}")
    end

    def get(url,params=nil,headers=nil)
      request_url = create_url(url,params)
      @logger.debug("GET #{request_url}")
      xml = RestClient.get(request_url)
      response = GliffyResponse.parse(xml)
      @logger.debug("Got a #{response.element.class.to_s}")
      return response
    end

    private

    def create_url(url,params)
      url = SignedURL.new(@api_key,@secret_key,@gliffy_root,url)
      url.params=params if params
      url['token'] = @current_token if @current_token

      url.full_url
    end
  end

  # Handles signing and assembling the URL
  class SignedURL
    def initialize(api_key,secret_key,url_root,url)
      @params = Hash.new
      @params['apiKey'] = api_key
      @secret_key = secret_key
      @url_root = url_root
      @url = url
    end

    # Sets a request parameter
    #
    # [param] the name of the parameter, as a string
    # [value] the value of the parameter, unencoded
    #
    def []=(param,value)
      if (param == 'apiKey')
        raise 'You may not override the api_key in this way'
      end
      @params[param] = value
    end

    # Sets all request parameters to those in the hash.
    def params=(params_hash)
      api_key = @params['apiKey']
      @params.replace(params_hash)
      @params['apiKey'] = api_key
    end

    # Gets the full URL, signed and ready to be requested
    def full_url
      to_sign = @url
      url_params = Hash.new
      @params.keys.sort.each do |key|
        to_sign += key
        to_sign += @params[key]
        url_params[key.to_s] = @params[key]
      end
      to_sign += @secret_key
      signature = Digest::MD5.hexdigest(to_sign)
      url_params['signature'] = signature

      url = @url_root + @url + '?'
      url_params.keys.sort.each do |key|
        val = CGI::escape(url_params[key])
        url += "#{key}=#{val}&"
      end
      url.gsub!(/\&$/,'')
      return url
    end
  end

end
