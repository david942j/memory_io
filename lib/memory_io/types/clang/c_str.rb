# encoding: ascii-8bit
# frozen_string_literal: true

require 'memory_io/types/type'

module MemoryIO
  module Types
    # @api private
    #
    # Define structures used in C language.
    module Clang
      # A null-terminated string.
      class CStr < Types::Type

        # Number of bytes to fetch at a time while searching for the terminator.
        CHUNK_SIZE = 1024

        # @api private
        #
        # The terminator is searched for in blocks rather than byte by byte,
        # and +stream+ is left just after it so the next read starts at the
        # following string.
        #
        # @return [String]
        #   String without null byte.
        def self.read(stream)
          ret = +''
          loop do
            chunk = stream.read(CHUNK_SIZE)
            break if chunk.nil? || chunk.empty?

            terminator = chunk.index("\x00")
            if terminator
              ret << chunk[0, terminator]
              stream.pos -= chunk.size - terminator - 1
              break
            end

            ret << chunk
          end
          ret
        end

        # @api private
        #
        # @param [String] val
        #   A null byte would be appended if +val+ not ends with null byte.
        def self.write(stream, val)
          val = val.to_s
          val += "\x00" unless val.end_with?("\x00")
          stream.write(val)
        end
      end
    end
  end
end
