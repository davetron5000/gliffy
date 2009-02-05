$:.unshift File.dirname(__FILE__)
require 'fileutils'
require 'yaml'
require 'gliffy'
require 'logger'

module Gliffy
  extend self

  # Represents the configuration for the command line client.
  # This is a singleton
  class CLIConfig

    @@instance = nil

    # Access to the singleton
    def self.instance 
      @@instance = CLIConfig.new if !@@instance
      @@instance
    end

    # Returns the config hash
    attr_reader :config

    # Loads the user's rc file if it exists, creating it if not
    def load
      if !File.exist?(@config_file_name)
        puts "#{@config_file_name} not found.  Create? [y/n]"
        answer = STDIN.gets
        if answer =~ /^[Yy]/
          save
        else
          puts "Aborting..."
          return false
        end
      end
      yaml_config = File.open(@config_file_name) { |file| YAML::load(file) }
      if (yaml_config)
        @config = yaml_config
      end
      @config[:open_url] = default_open_url if !@config[:open_url]
      @config[:open_image] = default_open_image if !@config[:open_image]
      read_config_from_user('API Key',:api_key)
      read_config_from_user('Secret Key',:secret_key)
      read_config_from_user('Account Name',:account_name)
      read_config_from_user('Username',:username)
      save
      config = Gliffy::Config.config
      @config.each() do |key,value|
        method = key.to_s + "="
        if config.respond_to? method.to_sym
          if (method == 'log_device=')
            if (value == 'STDERR')
              config.log_device = STDERR
            elsif (value == 'STDOUT')
              config.log_device = STDOUT
            else
              config.log_device = value
            end
          else
            config.send(method.to_sym,value)
          end
        end
      end
    end

    # Saves the configration to the user's config file name as YAML
    def save
      fp = File.open(@config_file_name,'w') { |out| YAML::dump(@config,out) }
    end

    private
    def read_config_from_user(name,symbol)
      if (!@config[symbol])
        puts "No #{name} configured.  Enter #{name}"
        @config[symbol] = STDIN.gets.chomp!
      end
    end

    def initialize
      @config_file_name = File.expand_path("~/.gliffyrc")
      @config = {
        :log_level => Gliffy::Config.config.log_level,
        :log_device => Gliffy::Config.config.log_device.to_s,
        :gliffy_app_root => Gliffy::Config.config.gliffy_app_root,
        :gliffy_rest_context => Gliffy::Config.config.gliffy_rest_context,
        :protocol => Gliffy::Config.config.protocol,
      }
    end

    def default_open_url
      # Cheesy defaults
      if RUBY_PLATFORM =~ /win32/
        # not sure, acutally
        nil
      elsif RUBY_PLATFORM =~ /linux/
        'firefox "%s"'
      elsif RUBY_PLATFORM =~ /darwin/
        'open "%s"'
      else
        nil
      end
    end

    def default_open_image
      # Cheesy defaults
      if RUBY_PLATFORM =~ /win32/
        # not sure, acutally
        nil
      elsif RUBY_PLATFORM =~ /linux/
        # not sure
        nil
      elsif RUBY_PLATFORM =~ /darwin/
        'open "%s"'
      else
        nil
      end
    end


  end

  def format_date(date)
    date.strftime('%m/%d/%y %H:%M')
  end

end

