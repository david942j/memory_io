# encoding: ascii-8bit

require 'memory_io/types/type'

module MemoryIO
  module Types
    # @api private
    #
    # Define structures used in C language.
    module Clang
      # A null-terminated string.
      class CStr < Types::Type
        # @api private
        #
        # @return [String]
        #   String without null byte.
        def self.read(stream)
          ret = ''
          loop do
            c = stream.read(1)
            break if c.nil? || c == '' || c == "\x00"
            ret << c
          end
          ret
        end

        # @api private
        #
        # @param [String] val
        #   A null byte would be appended if +val+ not ends with null byte.
        def self.write(stream, val)
          val = val.to_s
          val << "\x00" unless val.end_with?("\x00")
          stream.write(val)
        end
      end
    end
  end
end
