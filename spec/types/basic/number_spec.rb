# frozen_string_literal: true

require 'memory_io/types/basic/number'
require 'memory_io/types/types'

describe MemoryIO::Types::Basic::Number do
  describe :read do
    it 'unsigned' do
      stream = StringIO.new("\xff" * 100)
      expect(MemoryIO::Types.find(:u8).read(stream)).to eq 0xff
      expect(MemoryIO::Types.find(:u16).read(stream)).to eq 0xffff
      expect(MemoryIO::Types.find(:u32).read(stream)).to eq 0xffffffff
      expect(MemoryIO::Types.find(:u64).read(stream)).to eq 0xffffffffffffffff
    end

    it 'signed' do
      stream = StringIO.new("\xff" * 100)
      expect(MemoryIO::Types.find(:s8).read(stream)).to eq(-1)
      expect(MemoryIO::Types.find(:s16).read(stream)).to eq(-1)
      expect(MemoryIO::Types.find(:s32).read(stream)).to eq(-1)
      expect(MemoryIO::Types.find(:s64).read(stream)).to eq(-1)
    end

    it 'floating' do
      stream = StringIO.new("\x00\x00\x80\xBF")
      expect(MemoryIO::Types.find(:float).read(stream)).to eq(-1.0)
      stream = StringIO.new("\x00\x00\x00\x00\x00\x00\xF0\xBF")
      expect(MemoryIO::Types.find(:double).read(stream)).to eq(-1.0)
    end

    it 'reads a real whose magnitude exceeds the signed integer range' do
      stream = StringIO.new
      MemoryIO::Types.find(:float).write(stream, 1.5e10)
      stream.pos = 0
      expect(MemoryIO::Types.find(:float).read(stream)).to eq 15_000_000_512.0
      stream.string = +''
      MemoryIO::Types.find(:double).write(stream, 1.5e30)
      stream.pos = 0
      expect(MemoryIO::Types.find(:double).read(stream)).to eq 1.5e30
    end

    it 'reads the byte order of the context' do
      big = ->(str) { MemoryIO::Stream.new(StringIO.new(str), MemoryIO::Context.new(endian: :big)) }
      expect(MemoryIO::Types.find(:u32).read(big.call("\x12\x34\x56\x78"))).to eq 0x12345678
      expect(MemoryIO::Types.find(:s16).read(big.call("\xff\xfe"))).to eq(-2)
      expect(MemoryIO::Types.find(:float).read(big.call("\xBF\x80\x00\x00"))).to eq(-1.0)
      expect(MemoryIO::Types.find(:u8).read(big.call("\xff"))).to eq 0xff
    end
  end

  describe :write do
    it 'integer' do
      stream = StringIO.new
      MemoryIO::Types.find(:u64).write(stream, 0xdeadbeef12345678)
      expect(stream.string).to eq "\x78\x56\x34\x12\xef\xbe\xad\xde"
      stream.string = +''
      MemoryIO::Types.find(:s64).write(stream, -0x21524110edcba988)
      expect(stream.string).to eq "\x78\x56\x34\x12\xef\xbe\xad\xde"
    end

    it 'floating' do
      stream = StringIO.new
      MemoryIO::Types.find(:float).write(stream, -0.123)
      expect(stream.string).to eq "m\xE7\xFB\xBD"
      stream.string = +''
      MemoryIO::Types.find(:double).write(stream, -0.123)
      expect(stream.string).to eq "\xB0rh\x91\xED|\xBF\xBF"
    end

    it 'writes the byte order of the context' do
      %i[little big].each do |endian|
        stream = StringIO.new
        tagged = MemoryIO::Stream.new(stream, MemoryIO::Context.new(endian: endian))
        MemoryIO::Types.find(:u32).write(tagged, 0x12345678)
        expect(stream.string).to eq(endian == :little ? "\x78\x56\x34\x12" : "\x12\x34\x56\x78")
        stream.string = +''
        MemoryIO::Types.find(:float).write(tagged, 1.0)
        expect(stream.string).to eq(endian == :little ? "\x00\x00\x80\x3f" : "\x3f\x80\x00\x00")
      end
    end

    it 'rejects a value that does not fit' do
      stream = StringIO.new
      expect { MemoryIO::Types.find(:u32).write(stream, 2**32) }.to \
        raise_error(MemoryIO::ValueOutOfRangeError,
                    '0x100000000 is out of range for 32-bit unsigned integer (0x0..0xffffffff)')
      expect { MemoryIO::Types.find(:u32).write(stream, -1) }.to \
        raise_error(MemoryIO::ValueOutOfRangeError,
                    '-0x1 is out of range for 32-bit unsigned integer (0x0..0xffffffff)')
      expect { MemoryIO::Types.find(:s8).write(stream, 128) }.to \
        raise_error(MemoryIO::ValueOutOfRangeError,
                    '0x80 is out of range for 8-bit signed integer (-0x80..0x7f)')
      expect { MemoryIO::Types.find(:s8).write(stream, -129) }.to raise_error(MemoryIO::Error)
      expect(stream.string).to be_empty
    end

    it 'accepts the boundaries of each type' do
      stream = StringIO.new
      expect { MemoryIO::Types.find(:u8).write(stream, 0) }.to_not raise_error
      expect { MemoryIO::Types.find(:u8).write(stream, 0xff) }.to_not raise_error
      expect { MemoryIO::Types.find(:s8).write(stream, -0x80) }.to_not raise_error
      expect { MemoryIO::Types.find(:s8).write(stream, 0x7f) }.to_not raise_error
      expect { MemoryIO::Types.find(:u64).write(stream, (2**64) - 1) }.to_not raise_error
      expect { MemoryIO::Types.find(:s64).write(stream, -(2**63)) }.to_not raise_error
    end

    it 'accepts any representable floating value' do
      stream = StringIO.new
      expect { MemoryIO::Types.find(:float).write(stream, -1.0e30) }.to_not raise_error
      expect { MemoryIO::Types.find(:float).write(stream, 3.4e38) }.to_not raise_error
      expect { MemoryIO::Types.find(:double).write(stream, -1.0e300) }.to_not raise_error
      # losing precision is inherent to the type, not an error
      expect { MemoryIO::Types.find(:float).write(stream, 0.1) }.to_not raise_error
      # an infinity that was asked for is representable
      expect { MemoryIO::Types.find(:float).write(stream, Float::INFINITY) }.to_not raise_error
      expect { MemoryIO::Types.find(:float).write(stream, Float::NAN) }.to_not raise_error
    end

    it 'rejects a floating value that overflows the type' do
      stream = StringIO.new
      expect { MemoryIO::Types.find(:float).write(stream, 3.5e38) }.to \
        raise_error(MemoryIO::ValueOutOfRangeError, '3.5e+38 exceeds the range of 32-bit floating number')
      expect { MemoryIO::Types.find(:float).write(stream, -1.0e39) }.to \
        raise_error(MemoryIO::ValueOutOfRangeError, '-1.0e+39 exceeds the range of 32-bit floating number')
      # no Float can overflow a double, but an Integer can
      expect { MemoryIO::Types.find(:double).write(stream, 2**1024) }.to \
        raise_error(MemoryIO::ValueOutOfRangeError)
      expect(stream.string).to be_empty
    end
  end
end
