# coding: utf-8
#
# collapsium-config
# https://github.com/jfinkhaeuser/collapsium-config
#
# Copyright (c) 2016 Jens Finkhaeuser and other collapsium-config contributors.
# All rights reserved.
#

require 'collapsium'

module Collapsium
  module Config
    ##
    # Contains support code
    module Support
      ##
      # Contains helper functions for parsing configuration values.
      module Values

        ##
        # Given the value, turn it into an Array:
        # - comma-separated strings are split
        # - other single values are wrapped into an Array
        def array_value(value)
          # Split comma-separated strings.
          if value.respond_to? :split
            value = value.split(/,/)
          end

          # If the value is an Array, we strip its string elements.
          if value.is_a? Array
            value = value.map do |v|
              if v.respond_to? :strip
                next v.strip
              end
              next v
            end
          else
            # Otherwise turn the value into an Array if it's a single
            # value.
            value = [value]
          end

          return value
        end
      end # module Values
    end # module Support
  end # module Config
end # module Collapsium
