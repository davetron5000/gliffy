require 'logger'

module Gliffy

  # Global Configuration for Gliffy.
  # You can simply monkeypatch this to get different values, for example
  #
  #     class Gliffy::Config
  #       def self.log_level; Logger::ERROR; end
  #     end
  class Config

    attr_accessor :log_level
    attr_accessor :log_device
    attr_accessor :gliffy_root
    attr_accessor :protocol
    attr_accessor :api_key
    attr_accessor :secret_key

    @@instance = Config.new

    def initialize
      @log_level = Logger::DEBUG
      @log_device = STDERR
      @protocol = 'http'
      @gliffy_root = "#{@protocol}://www.gliffy.com/gliffy/rest"
      @api_key = 'no api key specified'
      @secret_key = 'no secret key specified'
    end

    def self.config=(config); @@instance = config; end
    def self.config; @@instance; end

    # Returns the log level for all logger
    def self.log_level
      @@instance.log_level
    end

    # Returns the "device" for logging, either a string (filename) or an IO instance
    def self.log_device
      @@instance.log_device
    end

    # Returns the root to the Gliffy API
    def self.gliffy_root
      @@instance.gliffy_root
    end

    # Returns the protocol to use, either 'http', or 'https'
    def self.protocol
      @@instance.protocol
    end

    # Returns your api key
    def self.api_key
      @@instance.api_key
    end

    # Returns your secret key
    def self.secret_key
      @@instance.secret_key
    end
  end
end

