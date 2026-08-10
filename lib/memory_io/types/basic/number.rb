# frozen_string_literal: true

require 'memory_io/context'
require 'memory_io/error'
require 'memory_io/types/type'

module MemoryIO
  module Types
    # Define native types such as integers and floating numbers.
    module Basic
      # Register numbers to {Types}.
      #
      # The byte order is taken from the {MemoryIO::Context} of the stream being
      # read, so the same type reads correctly from memory of either byte order.
      #
      # This class registered (un)signed (8, 16, 32, 64)-bit integers and IEEE-754 floating numbers.
      class Number
        # Indicators of the integer widths, by size in bytes.
        # A single byte has no byte order to indicate.
        INTEGER_INDICATORS = { 1 => 'C', 2 => 'S', 4 => 'L', 8 => 'Q' }.freeze

        # Indicators of the real widths, by size in bytes and then byte order.
        #
        # @example
        #   # 'e' and 'E' are IEEE-754 single and double precision, little endian.
        REAL_INDICATORS = { 4 => { little: 'e', big: 'g' }, 8 => { little: 'E', big: 'G' } }.freeze

        # Appended to an integer indicator to fix its byte order.
        ENDIAN_INDICATORS = { little: '<', big: '>' }.freeze

        # @param [Integer] bytes
        #   Bytes.
        # @param [Boolean] signed
        #   Signed or unsigned.
        # @param [Boolean] real
        #   Whether this type holds a real number rather than an integer.
        def initialize(bytes, signed, real: false)
          @bytes = bytes
          @signed = signed
          @real = real
          @range = value_range unless real
          @indicators = ENDIAN_INDICATORS.keys.to_h { |e| [e, indicator(e)] }
        end

        # @return [Integer]
        #
        # @raise [EOFError]
        #   Fewer than +bytes+ bytes remain in +stream+.
        def read(stream)
          endian = MemoryIO::Context.of(stream).endian
          unpack(MemoryIO::Util.read_exactly(stream, @bytes), endian)
        end

        # @param [Integer] val
        #
        # @raise [MemoryIO::ValueOutOfRangeError]
        #   +val+ doesn't fit in this type, which would otherwise be written truncated.
        def write(stream, val)
          endian = MemoryIO::Context.of(stream).endian
          raise MemoryIO::ValueOutOfRangeError, out_of_range_message(val) if out_of_range?(val, endian)

          stream.write(pack(val, endian))
        end

        private

        # Anything that isn't a number of the matching kind is left for
        # +Array#pack+ to reject.
        #
        # @return [Boolean]
        def out_of_range?(val, endian)
          if @range
            val.is_a?(Integer) && !@range.cover?(val)
          else
            val.is_a?(Numeric) && overflows?(val, endian)
          end
        end

        # A finite value that packs to an infinity has exceeded what the type
        # can represent. Losing precision is inherent to the type and allowed,
        # as is writing an infinity that was asked for.
        #
        # @return [Boolean]
        def overflows?(val, endian)
          val.infinite?.nil? && pack(val, endian).unpack1(@indicators[endian]).infinite?
        end

        # @return [Range]
        def value_range
          bits = @bytes * 8
          @signed ? (-(2**(bits - 1))..((2**(bits - 1)) - 1)) : (0..((2**bits) - 1))
        end

        # @return [String]
        def out_of_range_message(val)
          return format('%s exceeds the range of %d-bit floating number', val, @bytes * 8) unless @range

          format('%s is out of range for %d-bit %s integer (%s..%s)',
                 hex(val), @bytes * 8, @signed ? 'signed' : 'unsigned',
                 hex(@range.first), hex(@range.last))
        end

        # +format+'s '%#x' renders a negative number in two's complement notation.
        #
        # @return [String]
        #
        # @example
        #   hex(-128)
        #   #=> '-0x80'
        def hex(val)
          format('%s0x%x', val.negative? ? '-' : '', val.abs)
        end

        # @return [String]
        #   The +Array#pack+ indicator of this type in +endian+ byte order.
        def indicator(endian)
          return REAL_INDICATORS[@bytes][endian] if @real
          return INTEGER_INDICATORS[@bytes] if @bytes == 1

          INTEGER_INDICATORS[@bytes] + ENDIAN_INDICATORS[endian]
        end

        def unpack(str, endian)
          val = str.unpack1(@indicators[endian])
          # a real is already signed by its representation
          return val if @real

          val -= (2**(@bytes * 8)) if @signed && val >= (2**((@bytes * 8) - 1))
          val
        end

        def pack(val, endian)
          [val].pack(@indicators[endian])
        end

        # Register (un)signed n-bits integers.
        [8, 16, 32, 64].each do |t|
          Type.register(Number.new(t / 8, true),
                        alias: [:"basic/s#{t}", :"s#{t}"],
                        doc: "A signed #{t}-bit integer.")
          Type.register(Number.new(t / 8, false),
                        alias: [:"basic/u#{t}", :"u#{t}"],
                        doc: "An unsigned #{t}-bit integer.")
        end

        # Register floating numbers.
        Type.register(Number.new(4, true, real: true),
                      alias: %i[basic/float float],
                      doc: 'IEEE-754 32-bit floating number.')
        Type.register(Number.new(8, true, real: true),
                      alias: %i[basic/double double],
                      doc: 'IEEE-754 64-bit floating number.')
      end
    end
  end
end
