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

    @@instance=nil

    def initialize
      @log_level = Logger::DEBUG
      @log_device = STDERR
      @protocol = 'http'
      @gliffy_root = "#{@protocol}://www.gliffy.com/gliffy/rest"
      @api_key = 'no api key specified'
      @secret_key = 'no secret key specified'
    end

    def self.config=(config); @@instance = config; end
    def self.config
      @@instance = Config.new if !@@instance
      @@instance
    end
  end
end

