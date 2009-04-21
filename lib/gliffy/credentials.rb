require 'base64'
module Gliffy
  # Encapsulates all the information needed to make a request of Gliffy
  # outside of request-specific information.
  class Credentials
    @@counter = 1
    attr_reader :consumer_key
    attr_reader :consumer_secret
    attr_reader :access_token
    attr_reader :access_secret
    attr_reader :username
    attr_reader :account_id
    attr_reader :description

    # Create a new Credentials object.
    #
    # [+consumer_key+] The OAuth consumer key given to you when you signed up
    # [+consumer_secret+] The OAuth consumer secret given to you when you signed up
    # [+description+] Description of the application you are writing
    # [+account_id+] Your account id
    # [+username+] the Gliffy user name/identifier
    # [+access_token+] The access token you were given, or nil if you don't have one yet
    # [+access_secret+] The access secret you were given, or nil if you don't have one yet
    def initialize(consumer_key, consumer_secret, description, account_id, username, access_token = nil, access_secret = nil)
      raise ArgumentError.new("consumer_key required") if consumer_key.nil?
      raise ArgumentError.new("consumer_secret required") if consumer_secret.nil?
      raise ArgumentError.new("description required") if description.nil? || description.strip == ''
      raise ArgumentError.new("account_id required") if account_id.nil?
      raise ArgumentError.new("username required") if username.nil?

      @consumer_key = consumer_key
      @consumer_secret = consumer_secret
      @username = username
      @access_token = access_token
      @access_secret = access_secret
      @description = description
      @account_id = account_id
    end

    def has_access_token?
      !(@access_token.nil? && @access_secret.nil?)
    end

    # Update the access token
    def update_access_token(token,secret)
      @username = username
      @access_token = token
      @access_secret = secret
    end

    # Clear the access token if, for some reason, you know the one
    # you have is bad.
    def clear_access_token
      update_access_token(nil,nil)
    end

    # Return a nonce that hasn't been used before (at least not in this space/time continuum)
    def nonce
      @@counter += 1
      return Base64.encode64((@@counter + rand(100) + Time.new.to_i).to_s).chomp
    end
  end
end
