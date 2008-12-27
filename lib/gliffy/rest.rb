require 'gliffy/response.rb'
require 'digest/md5'
require 'cgi'

module Gliffy

  # Provides REST access to Gliffy, handling the signing of the requests
  # and parsing of the results
  class Rest

    # Create an accessor to the Gliffy REST api
    #
    # [api_key] your Gliffy API ey
    # [secret_key] the shared secret for signing requests
    # [gliffy_root] root URL of the Gliffy API
    #
    def initialize(api_key,secret_key,gliffy_root = 'http://www.gliffy.com/rest')
      @api_key = api_key
      @secret_key = secret_key
      @gliffy_root = gliffy_root
      @current_token = nil
    end

    def get(url,params=nil,headers=nil)
    end
  end

  # Handles signing and assembling the URL
  class SignedURL
    def initialize(api_key,secret_key,url_root,url)
      @params = Hash.new
      @params['api_key'] = api_key
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
      if (param == 'api_key')
        raise 'You may not override the api_key in this way'
      end
      @params[param] = value
    end

    # Sets all request parameters to those in the hash.
    def params=(params_hash)
      api_key = @params['api_key']
      @params.replace(params_hash)
      @params['api_key'] = api_key
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
