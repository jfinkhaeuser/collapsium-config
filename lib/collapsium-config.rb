# coding: utf-8
#
# collapsium-config
# https://github.com/jfinkhaeuser/collapsium-config
#
# Copyright (c) 2016-2017 Jens Finkhaeuser and other collapsium-config contributors.
# All rights reserved.
#

require 'collapsium-config/version'

require 'collapsium-config/configuration'

module Collapsium
  # Include the Config module to get access to a #config function that provides
  # access to a global configuration object.
  module Config
    # The default configuration file path
    DEFAULT_CONFIG_PATH = 'config.yml'.freeze

    # Default options for configuration loading
    DEFAULT_CONFIG_OPTIONS = {
      resolve_extensions: true,
      nonexistent_base: :ignore,
      data: nil,
    }.freeze

    ##
    # Modules can have class methods, too, but it's a little more verbose to
    # provide them.
    module ClassMethods
      # Set the configuration file
      def config_file=(name)
        @config_file = name
      end

      # @return [String] the config file path, defaulting to 'config/config.yml'
      def config_file
        return @config_file || DEFAULT_CONFIG_PATH
      end

      # Set configuration loading options
      def config_options=(opts)
        @config_options = opts
      end

      # @return [Hash] configuration loading options
      def config_options
        return @config_options || DEFAULT_CONFIG_OPTIONS
      end

      # @api private
      attr_accessor :config
    end # module ClassMethods
    extend ClassMethods

    ##
    # Access the global configuration.
    def config
      if Config.config.nil? or Config.config.empty?
        begin
          Config.config = Configuration.load_config(Config.config_file,
                                                    Config.config_options)
        rescue Errno::ENOENT
          Config.config = {}
        end
      end

      return Config.config
    end
  end # module Config
end # module Collapsium
