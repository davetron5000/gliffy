require 'gliffy/config'
require 'cgi'
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

    # Ruby's SignedURL::encode doesn't encode spaces correctly
    def self.encode(string)
      string.gsub(/([^ a-zA-Z0-9_.-]+)/n) do
      '%' + $1.unpack('H2' * $1.size).join('%').upcase
      end.gsub(' ', '%20')
    end

    # Create a new SignedURL with the following options (all required unless otherwise stated):
    #
    # [:consumer_key] The OAuth consumer key
    # [:consumer_secret] The OAuth consumer secret
    # [:access_token] The OAuth user access token (optional)
    # [:access_secret] The OAuth user access token (required if :access_token provided, otherwise omit)
    # [:method] The HTTP Request method that will be made
    # [:url] The URL (without parameters) to request
    #
    def initialize(credentials,url,method)
      raise ArgumentError.new("credentials is required") if credentials.nil?
      raise ArgumentError.new("url is required") if url.nil?
      raise ArgumentError.new("method is required") if method.nil?

      # TODO externalize this somehow
      @logger = Logger.new(Config.config.log_device)
      @logger.level = Config.config.log_level

      @params = {
        'oauth_signature_method' => 'HMAC-SHA1',
        'oauth_version' => '1.0',
      }
      @params['oauth_consumer_key'] = credentials.consumer_key
      @params['oauth_token'] = credentials.access_token if credentials.access_token
      @consumer_secret = credentials.consumer_secret
      @access_secret = credentials.access_secret
      @method = method.upcase
      @url = url
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
      @logger.debug("OAuth Part 1 : #{@method}")
      escaped_url = SignedURL::encode(@url)
      to_sign = @method + "&" + escaped_url + "&"
      @logger.debug("OAuth Part 2 (raw) : #{@url}")
      @logger.debug("OAuth Part 2 (esc) : #{escaped_url}")
      url_params = Hash.new
      param_part = ""
      params = @params
      params['oauth_timestamp'] = timestamp.to_s
      params['oauth_nonce'] = nonce
      @params.keys.sort.each do |key|
        value = @params[key]
        raise ArgumentError.new("#{key} is nil; don't set params to be nil") if value.nil?
        
        @logger.debug("Adding param #{key} with value #{value} escaped as #{SignedURL::encode(value)}")
        param_part += SignedURL::encode(key)
        param_part += "="
        param_part += SignedURL::encode(value)
        param_part += '&'
        url_params[key] = SignedURL::encode(value)
      end
      param_part.gsub!(/&$/,'')
      escaped_params = SignedURL::encode(param_part)
      @logger.debug("OAuth Part 3 (raw) : #{param_part}")
      @logger.debug("OAuth Part 3 (esc) : #{escaped_params}")

      to_sign += escaped_params

      signing_key = SignedURL::encode(@consumer_secret) + "&" + SignedURL::encode(@access_secret.nil? ? "" : @access_secret)

      @logger.debug("Signing '#{to_sign}' with key '#{signing_key}'")

      sha1 = HMAC::SHA1.new(signing_key)
      sha1 << to_sign
      signature = Base64.encode64(sha1.digest())
      signature.chomp!

      @logger.debug("signature == '#{signature}'")

      url_params['oauth_signature'] = SignedURL::encode(signature)

      url = @url + '?'
      url_params.keys.sort.each do |key|
        val = url_params[key]
        url += "#{key}=#{val}&"
      end
      url.gsub!(/\&$/,'')
      return url
    end
  end
end
