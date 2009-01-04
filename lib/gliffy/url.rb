require 'gliffy/config'

module Gliffy
  # Handles signing and assembling the URL
  class SignedURL

    def initialize(api_key,secret_key,url_root,url)
      raise ArgumentError.new("api_key is required") if !api_key
      raise ArgumentError.new("secret_key is required") if !secret_key
      raise ArgumentError.new("url_root is required") if !url_root
      raise ArgumentError.new("url is required") if !url_root
      @logger = Logger.new(Config.config.log_device)
      @logger.level = Config.config.log_level
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
        raise ArgumentError.new('You may not override the api_key in this way')
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
      @logger.debug("Getting full_url of #{@url}")
      to_sign = @url
      url_params = Hash.new
      @params.keys.sort.each do |key|
        @logger.debug("Adding param #{key} (#{to_sign.class.to_s}, #{key.class.to_s}) : #{to_sign.to_s}")
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
