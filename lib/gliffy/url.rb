require 'gliffy/config'
require 'rubygems'
require 'hmac-sha1'
require 'base64'

module Gliffy

  # Handles signing and assembling the URL
  class SignedURL

    READ_ONLY_PARAMS = {
      'oauth_consumer_key' => true,
      'oauth_token' => true,
      'oauth_signature_method' => true,
      'oauth_version' => true,
      'oauth_nonce' => true,
      'oauth_timestamp' => true,
    }

    # Create a new SignedURL with the following options (all required unless otherwise stated):
    #
    # [:consumer_key] The OAuth consumer key
    # [:consumer_secret] The OAuth consumer secret
    # [:access_token] The OAuth user access token (optional)
    # [:access_secret] The OAuth user access token (required if :access_token provided, otherwise omit)
    # [:method] The HTTP Request method that will be made
    # [:url] The URL (without parameters) to request
    #
    def initialize(options)
      raise ArgumentError.new("consumer_key is required") if !options[:consumer_key]
      raise ArgumentError.new("consumer_secret is required") if !options[:consumer_secret]
      raise ArgumentError.new("url is required") if !options[:url]
      raise ArgumentError.new("method is required") if !options[:method]
      @logger = Logger.new(Config.config.log_device)
      @logger.level = Config.config.log_level
      @params = Hash.new
      @params['oauth_consumer_key'] = options[:consumer_key]
      @params['oauth_token'] = options[:access_token]
      @params['oauth_signature_method'] = 'HMAC-SHA1'
      @params['oauth_version'] = '1.0'
      @signing_key = "#{options[:consumer_secret]}&#{options[:access_secret]}"
      @method = options[:method].upcase
      @url = options[:url]
    end

    # Sets a request parameter
    #
    # [param] the name of the parameter, as a string or symbol
    # [value] the value of the parameter, unencoded
    #
    def []=(param,value)
      raise ArgumentError.new("param may not be nil") if param.nil?
      raise ArgumentError.new("value may not be nil") if value.nil?
      param = param.to_s
      raise ArgumentError.new("You may not override #{param}") if READ_ONLY_PARAMS[param]
      @params[param] = value.to_s
    end

    # Sets all request parameters to those in the hash.
    def params=(params_hash)
      params_hash.each do |k,v|
        self[k]=v
      end
    end

    # Gets the full URL, signed and ready to be requested
    def full_url(timestamp=Time.now.to_i,nonce=Time.now.to_i.to_s)
      @logger.debug("Getting full_url of #{@url}")
      to_sign = @method + "&" + CGI::escape(@url) + "&"
      url_params = Hash.new
      param_part = ""
      @params.keys.sort.each do |key|
        @logger.debug("Adding param #{key} (#{to_sign.class.to_s}, #{key.class.to_s}) : #{to_sign.to_s}")
        param_part += key
        param_part += "="
        param_part += @params[key]
        url_params[key] = CGI::escape(@params[key])
      end
      url_params['oauth_timestamp'] = timestamp.to_s
      url_params['oauth_nonce'] = nonce
      param_part += "oauth_timestamp=" + url_params['oauth_timestamp']
      param_part += "oauth_nonce=" + url_params['oauth_nonce']

      to_sign += CGI::escape(param_part)

      @logger.debug("Signing '#{to_sign}'")

      sha1 = HMAC::SHA1.new(@signing_key)
      sha1 << to_sign
      signature = Base64.encode64(sha1.digest())

      @logger.debug("signature == '#{signature}'")

      url_params['oauth_signature'] = signature

      url = @url + '?'
      url_params.keys.sort.each do |key|
        val = CGI::escape(url_params[key])
        url += "#{key}=#{val}&"
      end
      url.gsub!(/\&$/,'')
      return url
    end
  end
end
