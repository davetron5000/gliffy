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
      @params[:api_key] = api_key
      @secret_key = secret_key
      @url_root = url_root
      @url = url
    end

    # Gets the full URL, signed and ready to be requested
    def full_url
      to_sign = @url
      url_params = Hash.new
      @params.keys.sort.each do |key|
        to_sign += key.to_s
        to_sign += @params[key]
        url_params[key.to_s] = @params[key]
      end
      to_sign += @secret_key
      signature = Digest::MD5.hexdigest(to_sign)
      url_params['signature'] = signature

      url = @url_root + @url + '?'
      url_params.sort.each do |key_val|
        key = key_val[0]
        val = key_val[1]
        url += key.to_s
        url += '='
        url += CGI::escape(val)
        url += '&'
      end
      url.gsub!(/\&$/,'')
      return url
    end
  end

end
