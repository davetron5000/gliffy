require 'base64'
module Gliffy

  # Encapsulates a request token, which is what Gliffy returns when
  # you request a user's OAuth Token
  class AccessToken
    attr_reader :token
    attr_reader :secret

    # Create a new token
    # [+token+] the token itself
    # [+secret+] the token secret, used for signing requests
    def initialize(token,secret)
      raise ArgumentError.new('token is required') if token.nil?
      raise ArgumentError.new('secret is required') if secret.nil?
      @token = token
      @secret = secret
    end
  end

  # Encapsulates all the information needed to make a request of Gliffy
  # outside of request-specific information.
  class Credentials
    @@nonce_counter = 1
    @@last_nonce = nil
    attr_reader :consumer_key
    attr_reader :consumer_secret
    attr_reader :access_token
    attr_reader :username
    attr_reader :account_id
    attr_reader :description
    attr_reader :default_protocol

    # Create a new Credentials object.
    #
    # [+consumer_key+] The OAuth consumer key given to you when you signed up
    # [+consumer_secret+] The OAuth consumer secret given to you when you signed up
    # [+description+] Description of the application you are writing
    # [+account_id+] Your account id
    # [+username+] the Gliffy user name/identifier
    # [+access_token+] The access token you were given as a AccessToken, or nil if you don't have one yet.  
    def initialize(consumer_key, consumer_secret, description, account_id, username, default_protocol=:http, access_token = nil)
      raise ArgumentError.new("consumer_key required") if consumer_key.nil?
      raise ArgumentError.new("consumer_secret required") if consumer_secret.nil?
      raise ArgumentError.new("description required") if description.nil? || description.strip == ''
      raise ArgumentError.new("account_id required") if account_id.nil?
      raise ArgumentError.new("username required") if username.nil?

      @consumer_key = consumer_key
      @consumer_secret = consumer_secret
      @username = username
      @access_token = access_token
      @description = description
      @account_id = account_id
      @default_protocol = default_protocol
    end

    def has_access_token?
      !@access_token.nil?
    end

    # Update the access token
    def update_access_token(token)
      @access_token = token
      @access_token
    end

    # Clear the access token if, for some reason, you know the one
    # you have is bad.
    def clear_access_token
      update_access_token(nil)
    end

    # Return a nonce that hasn't been used before (at least not in this space/time continuum)
    def nonce
      @@nonce_counter += 1
      this_nonce = Base64.encode64((@@nonce_counter + rand(100) + Time.new.to_i).to_s).chomp
      return self.nonce if this_nonce == @@last_nonce
      @@last_nonce = this_nonce
      this_nonce
    end
  end
end
