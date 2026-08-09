# frozen_string_literal: true

require 'elftools'

require 'memory_io/stream'

module MemoryIO
  # Describes how the memory being accessed lays out its data.
  #
  # The layout belongs to the memory, not to the machine running this library.
  # They only coincide when the memory belongs to a process on the same host.
  class Context
    # Byte orders that can be asked for. +:native+ resolves to the byte order
    # of the host, which is the right answer whenever the memory belongs to a
    # process running on it.
    ENDIANS = %i[little big native].freeze

    # The byte order of the host.
    NATIVE_ENDIAN = [1].pack('S') == "\x01\x00".b ? :little : :big

    # Assumed when nothing more specific is known.
    DEFAULT_POINTER_SIZE = 8

    # @return [:little, :big]
    #   Byte order of the memory. +:native+ has already been resolved.
    attr_reader :endian

    # @return [Integer]
    #   Size of a pointer, in bytes.
    attr_reader :pointer_size

    # @return [Hash]
    #   The attributes, in the form {#initialize} accepts.
    def to_h
      { endian: endian, pointer_size: pointer_size }
    end

    # @param [:little, :big, :native] endian
    #   Byte order of the memory.
    # @param [Integer] pointer_size
    #   Size of a pointer, in bytes.
    #
    # @raise [ArgumentError]
    #   +endian+ is not one of {ENDIANS}.
    #
    # @example
    #   Context.new(endian: :big).endian
    #   #=> :big
    def initialize(endian: :native, pointer_size: DEFAULT_POINTER_SIZE)
      raise ArgumentError, "endian must be one of #{ENDIANS.inspect}, got #{endian.inspect}" \
        unless ENDIANS.include?(endian)

      @endian = endian == :native ? NATIVE_ENDIAN : endian
      @pointer_size = pointer_size
    end

    class << self
      # @return [MemoryIO::Context]
      #   Used when a stream carries no context of its own.
      def default
        @default ||= new
      end

      # @param [Object] stream
      #   The stream a type is reading from.
      #
      # @return [MemoryIO::Context]
      #   The context +stream+ was tagged with, or {.default} when it carries none.
      def of(stream)
        stream.is_a?(MemoryIO::Stream) ? stream.context : default
      end

      # Derive a context from an ELF file, which describes the layout of the
      # memory it is loaded into.
      #
      # @param [String] path
      #   Path of the ELF file.
      #
      # @return [MemoryIO::Context?]
      #   +nil+ if +path+ is unreadable or is not an ELF file.
      #
      # @example
      #   Context.from_elf('/proc/self/exe')
      #   #=> #<MemoryIO::Context @endian=:little, @pointer_size=8>
      def from_elf(path)
        ::File.open(path, 'rb') do |file|
          elf = ELFTools::ELFFile.new(file)
          new(endian: elf.endian, pointer_size: elf.elf_class / 8)
        end
      rescue SystemCallError, ELFTools::ELFError
        nil
      end
    end
  end
end
