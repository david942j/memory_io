# encoding: ascii-8bit
# frozen_string_literal: true

require 'memory_io/types/types'

module MemoryIO
  # Main class to use {MemoryIO}.
  class IO
    attr_reader :stream # @return [#pos, #pos=, #read, #write]

    # Instantiate an {IO} object.
    #
    # @param [#pos, #pos=, #read, #write] stream
    #   The file-like object to be read/written.
    #   +file+ can be un-writable if you will not invoke any write-related method.
    #
    #   If +stream.read(*)+ returns empty string or +nil+, it would be seen as reaching EOF.
    def initialize(stream)
      @stream = stream
    end

    # Read and convert result into custom type/structure.
    #
    # @param [Integer] num_elements
    #   Number of elements to be read.
    #   This parameter must be positive and larger than zero.
    #
    #   This parameter may effect the return type,
    #   see documents of return value.
    # @param [Integer?] from
    #   Invoke +stream.pos = from+ before starting to read.
    #   +nil+ for not changing current position of stream.
    # @param [nil, Symbol, Proc] as
    #   Decide the type/structure when reading.
    #   See {MemoryIO::Types} for all supported types.
    #
    #   A +Proc+ is allowed, which should accept +stream+ as the first argument.
    #   The return value of the proc would be the return objects of this method.
    #
    #   If +nil+ is given, this method returns a string and has same behavior as +::IO#read+.
    # @param [Boolean] force_array
    #   When +num_elements+ equals to 1, the read +Object+ would be returned.
    #   Pass +true+ to this parameter to force this method returning an array.
    #
    # @return [String, Object, Array<Object>]
    #   There're multiple possible return types,
    #   which depends on the value of parameter +num_elements+, +as+, and +force_array+.
    #
    #   See examples for clear usage. The rule of return type is listed as following:
    #
    #   * +as = nil+:
    #     A +String+ with length +num_elements+ is returned.
    #   * +as != nil+ and +num_elements = 1+ and +force_array = false+:
    #     An +Object+ is returned. The type of +Object+ depends on parameter +as+.
    #   * +as != nil+ and +num_elements = 1+ and +force_array = true+:
    #     An array with one element is returned.
    #   * +as != nil+ and +num_elements > 1+:
    #     An array with length +num_elements+ is returned.
    #
    #   If EOF is occured, object(s) read will be returned.
    #
    # @example
    #   stream = StringIO.new('A' * 8 + 'B' * 8)
    #   io = MemoryIO::IO.new(stream)
    #   io.read(9)
    #   #=> "AAAAAAAAB"
    #   io.read(100)
    #   #=> "BBBBBBB"
    #
    #   # read two unsigned 32-bit integers starts from posistion 4
    #   io.read(2, from: 4, as: :u32)
    #   #=> [1094795585, 1111638594] # [0x41414141, 0x42424242]
    #
    #   io.read(1, as: :u16)
    #   #=> 16962 # 0x4242
    #   io.read(1, as: :u16, force_array: true)
    #   #=> [16962]
    # @example
    #   stream = StringIO.new("\xef\xbe\xad\xde")
    #   io = MemoryIO::IO.new(stream)
    #   io.read(1, as: :u32)
    #   #=> 3735928559
    #   io.rewind
    #   io.read(1, as: :s32)
    #   #=> -559038737
    # @example
    #   stream = StringIO.new("123\x0045678\x00")
    #   io = MemoryIO::IO.new(stream)
    #   io.read(2, as: :c_str)
    #   #=> ["123", "45678"]
    # @example
    #   # pass lambda to `as`
    #   stream = StringIO.new("\x03123\x044567")
    #   io = MemoryIO::IO.new(stream)
    #   io.read(2, as: lambda { |stream| stream.read(stream.read(1).ord) })
    #   #=> ["123", "4567"]
    #
    # @note
    #   This method's arguments and return value are different with +::IO#read+.
    #   Check documents and examples.
    #
    # @see Types
    def read(num_elements, from: nil, as: nil, force_array: false)
      stream.pos = from if from
      return stream.read(num_elements) if as.nil?

      conv = to_proc(as, :read)
      # TODO: handle eof
      ret = Array.new(num_elements) { conv.call(stream) }
      ret = ret.first if num_elements == 1 && !force_array
      ret
    end

    # Write to stream.
    #
    # @param [Object, Array<Object>] objects
    #   Objects to be written.
    #
    # @param [Integer] from
    #   The position to start to write.
    #
    # @param [nil, Symbol, Proc] as
    #   Decide the method to process writing procedure.
    #   See {MemoryIO::Types} for all supported types.
    #
    #   A +Proc+ is allowed, which should accept +stream+ and one object as arguments.
    #
    #   If +objects+ is a descendant instance of {Types::Type} and +as+ is +nil,
    #   +objects.class+ will be used for +as+.
    #   Otherwise, when +as = nil+, this method will simply call +stream.write(objects)+.
    #
    # @return [void]
    #
    # @example
    #   stream = StringIO.new
    #   io = MemoryIO::IO.new(stream)
    #   io.write('abcd')
    #   stream.string
    #   #=> "abcd"
    #
    #   io.write([1, 2, 3, 4], from: 2, as: :u16)
    #   stream.string
    #   #=> "ab\x01\x00\x02\x00\x03\x00\x04\x00"
    #
    #   io.write(['A', 'BB', 'CCC'], from: 0, as: :c_str)
    #   stream.string
    #   #=> "A\x00BB\x00CCC\x00\x00"
    # @example
    #   stream = StringIO.new
    #   io = MemoryIO::IO.new(stream)
    #   io.write(%w[123 4567], as: ->(s, str) { s.write(str.size.chr + str) })
    #   stream.string
    #   #=> "\x03123\x044567"
    #
    # @example
    #   stream = StringIO.new
    #   io = MemoryIO::IO.new(stream)
    #   cpp_string = CPP::String.new('A' * 4, 15, 16)
    #   # equivalent to io.write(cpp_string, as: :'cpp/string')
    #   io.write(cpp_string)
    #   stream.string
    #   #=> "\x10\x00\x00\x00\x00\x00\x00\x00\x04\x00\x00\x00\x00\x00\x00\x00AAAA\x00"
    # @see Types
    def write(objects, from: nil, as: nil)
      stream.pos = from if from
      as ||= objects.class if objects.class.ancestors.include?(MemoryIO::Types::Type)
      return stream.write(objects) if as.nil?

      conv = to_proc(as, :write)
      Array(objects).map { |o| conv.call(stream, o) }
    end

    # Set +stream+ to the beginning.
    # i.e. invoke +stream.pos = 0+.
    #
    # @return [0]
    def rewind
      stream.pos = 0
    end

    private

    # @api private
    def to_proc(as, rw)
      ret = as.respond_to?(rw) ? as.method(rw) : as
      ret = ret.respond_to?(:call) ? ret : MemoryIO::Types.get_proc(ret, rw)
      raise ArgumentError, <<-EOERR.strip unless ret.respond_to?(:call)

Invalid argument `as`: #{as.inspect}. It should be either a Proc or a supported type of MemoryIO::Types.
      EOERR

      ret
    end
  end
end
