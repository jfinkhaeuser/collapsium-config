# coding: utf-8
#
# collapsium-config
# https://github.com/jfinkhaeuser/collapsium-config
#
# Copyright (c) 2016 Jens Finkhaeuser and other collapsium-config contributors.
# All rights reserved.
#

require 'collapsium'

require 'collapsium-config/support/values'

module Collapsium
  module Config
    ##
    # The Config class extends UberHash by two main pieces of functionality:
    #
    # - it loads configuration files and turns them into pathed hashes, and
    # - it treats environment variables as overriding anything contained in
    #   the configuration file.
    #
    # For configuration file loading, a named configuration file will be laoaded
    # if present. A file with the same name but `-local` appended before the
    # extension will be loaded as well, overriding any values in the original
    # configuration file.
    #
    # For environment variable support, any environment variable named like a
    # path into the configuration hash, but with separators transformed to
    # underscore and all letters capitalized will override values from the
    # configuration files under that path, i.e. `FOO_BAR` will override
    # `'foo.bar'`.
    #
    # Environment variables can contain JSON *only*; if the value can be parsed
    # as JSON, it becomes a Hash in the configuration tree. If it cannot be parsed
    # as JSON, it remains a string.
    #
    # **Note:** if your configuration file's top-level structure is an array, it
    # will be returned as a hash with a 'config' key that maps to your file's
    # contents.
    # That means that if you are trying to merge a hash with an array config, the
    # result may be unexpected.
    class Configuration < ::Collapsium::UberHash
      include ::Collapsium::EnvironmentOverride
      include ::Collapsium::Config::Support::Values

      # @api private
      # Very simple YAML parser
      class YAMLParser
        require 'yaml'

        # @return parsed string
        def self.parse(string)
          return YAML.load(string)
        end
      end
      private_constant :YAMLParser

      # @api private
      # Very simple JSON parser
      class JSONParser
        require 'json'

        # @return parsed string
        def self.parse(string)
          return JSON.parse(string)
        end
      end
      private_constant :JSONParser

      def initialize(*args)
        super(*args)
      end

      class << self
        include ::Collapsium::Config::Support::Values

        # @api private
        # Mapping of file name extensions to parser types.
        FILE_TO_PARSER = {
          '.yml'  => YAMLParser,
          '.yaml' => YAMLParser,
          '.json' => JSONParser,
        }.freeze
        private_constant :FILE_TO_PARSER

        # @api private
        # If the config file contains an Array, this is what they key of the
        # returned Hash will be.
        ARRAY_KEY = 'config'.freeze
        private_constant :ARRAY_KEY

        ##
        # Loads a configuration file with the given file name. The format is
        # detected based on one of the extensions in FILE_TO_PARSER.
        #
        # @param path [String] the path of the configuration file to load.
        # @param options [Hash] options hash with the following keys:
        #   - resolve_extensions [Boolean] flag whether to resolve configuration
        #       hash extensions. (see `#resolve_extensions`)
        #   - data [Hash] data Hash to pass on to the templating mechanism.
        def load_config(path, options = {})
          # Option defaults
          if options[:resolve_extensions].nil?
            options[:resolve_extensions] = true
          end
          options[:data] ||= {}

          # Load base and local configuration files
          base, config = load_base_config(path, options[:data])
          _, local_config = load_local_config(base, options[:data])

          # Merge local configuration
          config.recursive_merge!(local_config)

          # Resolve includes
          config = resolve_includes(base, config, options)

          # Create config from the result
          cfg = Configuration.new(config)

          # Now resolve config hashes that extend other hashes.
          if options[:resolve_extensions]
            cfg.resolve_extensions!
          end

          return cfg
        end

        private

        def parse(extension, contents, data)
          # Evaluate template
          require 'erb'
          b = binding
          contents = ERB.new(contents).result(b)

          # Pass on to file type parser
          return FILE_TO_PARSER[extension].parse(contents)
        end

        def load_base_config(path, template_data)
          # Make sure the format is recognized early on.
          base = Pathname.new(path)
          formats = FILE_TO_PARSER.keys
          if not formats.include?(base.extname)
            raise ArgumentError, "Files with extension '#{base.extname}' are not"\
                  " recognized; please use one of #{formats}!"
          end

          # Don't check the path whether it exists - loading a nonexistent
          # file will throw a nice error for the user to catch.
          file = base.open
          contents = file.read

          # Parse the contents.
          config = parse(base.extname, contents, template_data)

          return base, Configuration.new(hashify(config))
        end

        def load_local_config(base, template_data)
          # Now construct a file name for a local override.
          local = Pathname.new(base.dirname)
          local = local.join(base.basename(base.extname).to_s + "-local" +
              base.extname)
          if not local.exist?
            return local, nil
          end

          # We know the local override file exists, but we do want to let any
          # errors go through that come with reading or parsing it.
          file = local.open
          contents = file.read

          local_config = parse(base.extname, contents, template_data)

          return local, Configuration.new(hashify(local_config))
        end

        def hashify(data)
          if data.nil?
            return {}
          end
          if data.is_a? Array
            data = { ARRAY_KEY => data }
          end
          return data
        end

        def resolve_includes(base, config, options)
          # Only process Hashes
          if not config.is_a? Hash
            # :nocov:
            return config
            # :nocov:
          end

          # Figure out includes. We have to recursively fetch the string and
          # the symbol keys, and process includes where we find them.
          ["include", :include].each do |key|
            config.recursive_fetch_all(key) do |parent, value, _|
              # The value contains the includes
              includes = array_value(value)
              parent.delete(key)

              # Now merge all includes into the parent
              includes.each do |filename|
                # Load included file
                incfile = Pathname.new(base.dirname)
                incfile = incfile.join(filename)

                # Due to the way recursive_fetch works, we may get bad
                included = Configuration.load_config(incfile, options)

                # Merge included
                parent.recursive_merge!(hashify(included), true)
              end
            end
          end

          return config
        end
      end # class << self

      ##
      # Resolve extensions in configuration hashes. If your hash contains e.g.:
      #
      # ```yaml
      #   foo:
      #     bar:
      #       some: value
      #     baz:
      #       extends: bar
      # ```
      #
      # Then `'foo.baz.some'` will equal `'value'` after resolving extensions. Note
      # that `:load_config` calls this function, so normally you don't need to call
      # it yourself. You can switch this behaviour off in `:load_config`.
      #
      # Note that this process has some intended side-effects:
      #
      # 1. If a hash can't be extended because the base cannot be found, an error
      #    is raised.
      # 1. If a hash got successfully extended, the `extends` keyword itself is
      #    removed from the hash.
      # 1. In a successfully extended hash, an `base` keyword, which contains
      #    the name of the base. In case of multiple recursive extensions, the
      #    final base is stored here.
      #
      # Also note that all of this means that :extends and :base are reserved
      # keywords that cannot be used in configuration files other than for this
      # purpose!
      def resolve_extensions!
        # The root object is always a Hash, so has keys, which can be processed
        # recursively.
        recursive_resolve(self)
      end

      def recursive_resolve(root, prefix = "")
        # The self object is a Hash or an Array. Let's iterate over its children
        # one by one. Defaulting to a Hash here is just convenience, it could
        # equally be an Array.
        children = root.fetch(prefix, {})

        merge_base(root, prefix, children)

        if children.is_a? Hash
          children.each do |key, _|
            full_key = normalize_path("#{prefix}#{separator}#{key}")
            recursive_resolve(root, full_key)
          end
        elsif children.is_a? Array
          children.each_with_index do |_, idx|
            key = idx.to_s
            full_key = normalize_path("#{prefix}#{separator}#{key}")
            recursive_resolve(root, full_key)
          end
        end
      end

      def merge_base(root, path, value)
        # If the value is not a Hash, we can't do anything here.
        if not value.is_a? Hash
          return
        end

        # If the value contains an "extends" keyword, we can find the value's
        # base. Otherwise there's nothing to do.
        if not value.include? "extends"
          return
        end

        # Now to resolve the path to the base and remove the "extends" keyword.
        bases = fetch_base_values(root, parent_path(path), value)

        # Merge the bases
        merge_base_values(root, value, bases)

        # And we're done, set the value to what was being merged.
        root[path] = value
      end

      def fetch_base_values(root, parent, value)
        base_paths = array_value(value["extends"])
        bases = []
        base_paths.each do |base_path|
          if not base_path.start_with?(separator)
            base_path = "#{parent}#{separator}#{base_path}"
          end
          base_path = normalize_path(base_path)

          # Fetch the base value from the root. This makes full use of
          # PathedAccess.
          # We default to nil. Only Hash base values can be processed.
          base_value = root.fetch(base_path, nil)
          if not base_value.is_a? Hash
            next
          end

          bases << [base_path, base_value]
        end

        # Only delete the "extends" keyword if we found all base.
        if bases.length == base_paths.length
          value.delete("extends")
        end

        return bases
      end

      def merge_base_values(root, value, bases)
        # We need to recursively resolve the base values before merging them into
        # value. To preserve the override order, we need to overwrite values when
        # merging bases...
        merged_base = Configuration.new
        bases.each do |base_path, base_value|
          base_value.recursive_resolve(root, base_path)
          merged_base.recursive_merge!(base_value, true)

          # Modify bases for this path: we go depth first into the hierarchy
          base_val = merged_base.fetch("base", []).dup
          base_val << base_path
          base_val.uniq!
          merged_base["base"] = base_val
        end

        # ... but value needs to stay authoritative.
        value.recursive_merge!(merged_base, false)
      end
    end # class Configuration
  end # module Config
end # module Collapsium
