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

    protected

    def initialize(id,is_admin,username,email)
      super()
      @id = id
      @is_admin = is_admin
      @username = username
      @email = email
    end

  end

end
