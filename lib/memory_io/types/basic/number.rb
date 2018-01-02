require 'memory_io/types/type'

module MemoryIO
  module Types
    # @api private
    #
    # Define native types such as integers and floating numbers.
    module Basic
      # @api private
      # Register numbers to {Types}.
      #
      # All types registerd by this class are assumed as *little endian*.
      class Number
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
        end

        # @return [Integer]
        def read(stream)
          unpack(stream.read(@bytes))
        end

        # @param [Integer] val
        def write(stream, val)
          stream.write(pack(val))
        end

        private

        def unpack(str)
          val = str.unpack(@pack_str).first
          val -= (2**(@bytes * 8)) if @signed && val >= (2**(@bytes * 8 - 1))
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
          Type.register(Number.new(t / 8, true, c), alias: "s#{t}".to_sym)
          Type.register(Number.new(t / 8, false, c), alias: "u#{t}".to_sym)
        end

        # Register floating numbers.
        Type.register(Number.new(4, false, 'F'), alias: :float)
        Type.register(Number.new(8, false, 'D'), alias: :double)
      end
    end
  end
end
