# coding: utf-8
#
# collapsium-config
# https://github.com/jfinkhaeuser/collapsium-config
#
# Copyright (c) 2016 Jens Finkhaeuser and other collapsium-config contributors.
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
    end # module ClassMethods
    extend ClassMethods

    ##
    # Access the global configuration
    def config
      if @config.nil?
        begin
          @config = Configuration.load_config(Config.config_file)
        rescue Errno::ENOENT
          @config = {}
        end
      end

      return @config
    end
  end # module Config
end # module Collapsium
