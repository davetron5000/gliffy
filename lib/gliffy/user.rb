require 'rexml/document'
require 'array_has_response'
require 'gliffy/rest'

include REXML

module Gliffy

  # A user token
  class UserToken < Response
    attr_reader :expiration
    attr_reader :token
    def self.from_xml(element)
      expiration = Time.at(element.attributes['expiration'].to_i / 1000)
      token = element.text
      UserToken.new(expiration,token)
    end

    def expired?
      Time.now > expiration
    end

    protected

    def initialize(expiration,token)
      super()
      @expiration = expiration
      @token = token
    end

  end

  class Users < ArrayResponseParser; end

  # A user of Gliffy and the main entry point to using the API (see #initiate_session)
  class User < Response

    # The user's username, which is their identifier within an account
    attr_reader :username
    # The user's email, which is unique to them in the entire Gliffy system.
    # Note that this isn't guaranteed to be a real email, nor is
    # it guaranteed to be the user's actual email.  This is 
    # assigned by the system unless overridden by the API.
    attr_reader :email
    attr_reader :id

    # The UserToken currently assigned to this user (this won't necessarily have a value)
    attr_accessor :token

    def self.from_xml(element)
      id = element.attributes['id'].to_i
      is_admin = false
      is_admin = element.attributes['is-admin'] == 'true' if element.attributes['is-admin'] 
      username = element.elements['username'] ? element.elements['username'].text : nil
      email = element.elements['email'] ? element.elements['email'].text : nil

      User.new(id,is_admin,username,email)
    end

    # Returns true if this user is an admin of the account in which they live
    def is_admin?
      @is_admin
    end

    def self.initiate_session(username,rest=nil)
      raise ArgumentError('username is required') if !username
      logger = Logger.new(Config.config.log_device)
      logger.level = Config.config.log_level
      rest = Rest.new if !rest

      account_name = Config.config.account_name
      token = Response.from_xml(rest.get("/accounts/#{account_name}/users/#{username}/token"))
      if (token.success?)
        rest.current_token = token.token
        users = Response.from_xml(rest.get("/accounts/#{account_name}/users"))
        if (users.success?)
          users.each do |user|
            if user.username == username
              user.token = token
              user.rest = rest
              return user
            end
          end
          logger.error('Got the list of users, but didn''t find the user in that list?!?!?')
          Error.new("Although we got a token for #{username}, we couldn't find that user in the account's user list.  Something is very wrong",404);
        else
          logger.error('Problem getting user after successful retrieval of token');
          user # this is an Error actually
        end
      else
        logger.warn('Couldn''t get token');
        token # this is an Error actually
      end
    end

    def folders
      refresh_token if token.expired?
      Response.from_xml(rest.get("/accounts/#{account_name}/users/#{username}/folders"))
    end

    protected

    def account_name
      Config.config.account_name
    end

    def refresh_token
      token = Response.from_xml(rest.get("/accounts/#{account_name}/users/#{username}/token"))
      if (token.success?)
        rest.current_token = token.token
      end
    end

    def initialize(id,is_admin,username,email)
      super()
      @id = id
      @is_admin = is_admin
      @username = username
      @email = email
    end

  end

end
