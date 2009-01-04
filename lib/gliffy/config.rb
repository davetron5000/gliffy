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
  end
end

