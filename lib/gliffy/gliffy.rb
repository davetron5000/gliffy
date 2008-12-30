module Gliffy

  # A session-wide handle to Gliffy.  Typically you would create one of these per user of your application.
  class GliffyHandle

    # Create a new gliffy handle
    #
    # [rest] a Rest to access your account's Gliffy API
    # [account_name] the name of your account
    # [username] the name of the user whose session this handle belongs to. Note that this user must be unique to your account, but need not exist; they will be provisioned if they don't.
    #
    def initialize(rest,account_name,username,token=nil)

      @rest = rest
      @account_name = account_name
      @username = username
      @rest.current_token = token
      @logger = Logger.new(STDERR)
      @logger.level = Logger::DEBUG
      refresh_token if !token
    end

    def refresh_token
      @rest.current_token = nil
      token_response = @rest.get(url_for("users/#{@username}/token"))
      return if ! validate_response("Refreshing #{@username}'s token",token_response)
      @rest.current_token = token_response.element.token
    end

    # Entry point to your account's data.  Returns an Account
    def account
      response = @rest.get(url_for(""))
      if possibly_expired_token? response
        @logger.info("Token may have expired; fetching a new one if possible")
        refresh_token
        response = @rest.get(url_for(""))
      end
      return if ! validate_response("Refreshing #{@username}'s token",response)
      account = response.element[0]
      account.handle = self
      account
    end

    def method_missing(symbol,*args)
      response = @rest.send(symbol,*args)
      if possibly_expired_token? response
        @logger.info("Token may have expired; fetching a new one if possible")
        refresh_token
        response = @rest.send(symbol,*args)
      end
      if response.is_a? Response
        return if ! validate_response("",response)
      end
      response.handle=self if response.respond_to? :handle=
      response
    end

    # Called when an error is received from gliffy.
    # This implementation raises a RuntimeError. If you wish
    # different behavior, override this method.  This is only called
    # when the response is not successful.
    #
    # [operation] a message describing the operation being performed; not necessarily human consumable
    # [gliffy_error] an Error encapsulating the error that occured
    #
    def handle_error(operation,gliffy_error)
      raise "#{operation} : #{gliffy_error.message}"
    end

    def url_for(url)
      "/accounts/#{@account_name}/#{url}"
    end

    private

    def possibly_expired_token?(response)
      if response.respond_to? :success?
        if !response.success?
          return response.element.http_status == 401
        end
      end
      false
    end

    def validate_response(operation,response)
      if !response.success?
        handle_error(operation,response.element) 
        false
      else
        true
      end
    end

  end
end
