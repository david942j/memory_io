# frozen_string_literal: true

require 'memory_io/error'
require 'memory_io/types/type'

module MemoryIO
  module Types
    # Define native types such as integers and floating numbers.
    module Basic
      # Register numbers to {Types}.
      #
      # All types registered by this class are assumed as *little endian*.
      #
      # This class registered (un)signed (8, 16, 32, 64)-bit integers and IEEE-754 floating numbers.
      class Number
        # Pack indicators of the types that hold a real number. They overflow
        # by losing magnitude rather than by wrapping, so they are bounded
        # differently from the integer types.
        #
        # @example
        #   # 'F' and 'D' are IEEE-754 single and double precision.
        REAL_INDICATORS = %w[F D].freeze

        # @param [Integer] bytes
        #   Bytes.
        # @param [Boolean] signed
        #   Signed or unsigned.
        # @param [String] pack_str
        #   The indicator to be passed to +Array#pack+ and +String#unpack+.
        def initialize(bytes, signed, pack_str)
          @bytes = bytes
          @signed = signed
          @pack_str = pack_str
          @range = value_range unless REAL_INDICATORS.include?(pack_str)
        end

        # @return [Integer]
        #
        # @raise [EOFError]
        #   Fewer than +bytes+ bytes remain in +stream+.
        def read(stream)
          unpack(MemoryIO::Util.read_exactly(stream, @bytes))
        end

        # @param [Integer] val
        #
        # @raise [MemoryIO::ValueOutOfRangeError]
        #   +val+ doesn't fit in this type, which would otherwise be written truncated.
        def write(stream, val)
          raise MemoryIO::ValueOutOfRangeError, out_of_range_message(val) if out_of_range?(val)

          stream.write(pack(val))
        end

        private

        # Anything that isn't a number of the matching kind is left for
        # +Array#pack+ to reject.
        #
        # @return [Boolean]
        def out_of_range?(val)
          if @range
            val.is_a?(Integer) && !@range.cover?(val)
          else
            val.is_a?(Numeric) && overflows?(val)
          end
        end

        # A finite value that packs to an infinity has exceeded what the type
        # can represent. Losing precision is inherent to the type and allowed,
        # as is writing an infinity that was asked for.
        #
        # @return [Boolean]
        def overflows?(val)
          val.infinite?.nil? && pack(val).unpack1(@pack_str).infinite?
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

        def unpack(str)
          val = str.unpack1(@pack_str)
          val -= (2**(@bytes * 8)) if @signed && val >= (2**((@bytes * 8) - 1))
          val
        end

        def pack(val)
          [val].pack(@pack_str)
        end

        # Register (un)signed n-bits integers.
        {
          8 => 'C',
          16 => 'S',
          32 => 'I',
          64 => 'Q'
        }.each do |t, c|
          Type.register(Number.new(t / 8, true, c),
                        alias: [:"basic/s#{t}", :"s#{t}"],
                        doc: "A signed #{t}-bit integer.")
          Type.register(Number.new(t / 8, false, c),
                        alias: [:"basic/u#{t}", :"u#{t}"],
                        doc: "An unsigned #{t}-bit integer.")
        end

        # Register floating numbers.
        Type.register(Number.new(4, false, 'F'),
                      alias: %i[basic/float float],
                      doc: 'IEEE-754 32-bit floating number.')
        Type.register(Number.new(8, false, 'D'),
                      alias: %i[basic/double double],
                      doc: 'IEEE-754 64-bit floating number.')
      end
    end
  end
end
