require 'logger'

module Gliffy

  # Global Configuration for Gliffy.
  # You can simply monkeypatch this to get different values, for example
  #
  #     class Gliffy::Config
  #       def self.log_level; Logger::ERROR; end
  #     end
  class Config

    # Returns the log level for all logger
    def self.log_level
      Logger::DEBUG
    end

    # Returns the "device" for logging, either a string (filename) or an IO instance
    def self.log_device
      STDERR
    end

    # Returns the root to the Gliffy API
    def self.gliffy_root
      "#{protocol}://www.gliffy.com/gliffy/rest"
    end

    # Returns the protocol to use, either 'http', or 'https'
    def self.protocol
      'http'
    end

    # Returns your api key
    def self.api_key
      'no api key specified'
    end

    # Returns your secret key
    def self.secret_key
      'no secret key specified'
    end
  end
end

