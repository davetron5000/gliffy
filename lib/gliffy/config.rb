require 'logger'

module Gliffy

  # Global Configuration for Gliffy.  This is a singleton currently and can be accessed
  # via the config class method
  # 
  # * You mostly need to set api_key, secret_key and account_name
  # * You may wish to set protocol if you have a premium account and wish to use https
  class Config

    # A Logger level to control logging
    attr_accessor :log_level
    # The log device (as passed to Logger) for where log messages should go
    attr_accessor :log_device
    # The protocol, either 'http' or 'https' (though feel free to try 'gopher:' :)
    attr_accessor :protocol
    # The gliffy web root, which is pretty much www.gliffy.com unless you know a secret
    attr_accessor :gliffy_web_root
    # The url relative to gliffy_web_root of where the API is accessed
    attr_accessor :gliffy_rest_context
    # Your API Key
    attr_accessor :api_key
    # Your Secret Key
    attr_accessor :secret_key
    # The name of your account
    attr_accessor :account_name

    @@instance=nil

    def initialize
      @log_level = Logger::DEBUG
      @log_device = STDERR
      @protocol = 'http'
      @gliffy_web_root = 'www.gliffy.com';
      @gliffy_rest_context = 'gliffy/rest'
      @api_key = 'no api key specified'
      @secret_key = 'no secret key specified'
      @account_name = 'no account name specified'
    end

    # Returns the entire URL to the gliffy api root.  This uses protocol, gliffy_web_root
    # and gliffy_rest_context, so you should not really override this
    def gliffy_root
      "#{protocol}://#{gliffy_web_root}/#{gliffy_rest_context}"
    end

    def self.config=(config); @@instance = config; end
    def self.config
      @@instance = Config.new if !@@instance
      @@instance
    end
  end
end

