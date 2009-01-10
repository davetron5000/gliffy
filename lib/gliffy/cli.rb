$:.unshift File.dirname(__FILE__)
require 'fileutils'
require 'yaml'
require 'gliffy'
require 'logger'

module Gliffy
  extend self

  class Command

    GLOBAL_FLAGS = {
      '-v' => 'be more verbose (overrides config)',
    }
    
    def self.commands
      @@commands ||= {}
    end

    attr_reader :name
    attr_reader :description
    attr_reader :usage

    def initialize(name,description,offline,usage,block)
      @name = name
      @description = description
      @block = block
      @offline = offline
      @usage = usage ? usage : ""
    end

    def run(args)
      if (@offline)
        @block.call(args)
      else
        handle = Gliffy::Handle.new(CLIConfig.config.config[:username])
        @block.call(handle,args)
      end
    end

    def self.execute(argv)
      globals = Hash.new
      command = argv.shift
      while !command.nil? && (command =~ /^-/) && !argv.empty?
        globals[command] = true
        command = argv.shift
      end 
      Gliffy::Config.config.log_level = Logger::DEBUG if globals['-v']
      Gliffy::Command.commands[command.to_sym].run argv
    end
  end

  class CLIConfig

    @@instance = nil

    def self.config 
      @@instance = CLIConfig.new if !@@instance
      @@instance
    end

    # Returns the config hash
    attr_reader :config

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


  end

  def desc(description)
    @next_desc = description
  end

  def offline(bool)
    @next_offline = bool
  end

  def usage(usage='')
    @next_usage = usage
  end

  def command(name,options={},&block)
    Command.commands[name] = Command.new(name,@next_desc,@next_offline,@next_usage,block)
    if options[:aliases]
      options[:aliases].each() do |a|
        Command.commands[a] = Command.commands[name]
      end
    end
  end

end

include Gliffy
require 'gliffy/commands/commands'
config = CLIConfig.config
if !config.load
  exit -1
end


