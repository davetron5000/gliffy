require 'gliffy/request'
require 'gliffy/response'
require 'gliffy/credentials'

module Gliffy
  VERSION = '0.1.7'


  # A "handle" to access Gliffy on a per-user-session basis
  # Since most calls to gliffy require a user-token, this class
  # encapsulates that token and the calls made under it.
  #
  # The methods here are designed to raise exceptions if there are problems from Gliffy.
  # These problems usually indicate a programming error or a server-side problem with Gliffy and
  # are generally unhandleable.  However, if you wish to do something better than simply raise an exception
  # you may override handle_error to do something else
  #
  class Handle

    attr_reader :logger
    attr_reader :request
    attr_reader :token

    # Create a new handle to gliffy for the given user.  Tokens will be requested as needed
    def initialize(api_root,credentials,http=nil,logger=nil)
      @credentials = credentials
      @request = Request.new(api_root,credentials)
      @request.http = http if !http.nil?
      @logger = logger || Logger.new(STDOUT)
      @logger.level = Logger::INFO
      @request.logger = @logger
      if !@credentials.has_access_token?
        update_token
      end
    end

    def update_token
      response = @request.create('accounts/$account_id/users/$username/oauth_token.xml',
                      :description => @credentials.description,
                      :protocol_override => :https)
      @token = Response.from_http_response(response)
    end
  end
end
