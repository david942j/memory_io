require 'memory_io/types/basic/number'

describe MemoryIO::Types::Basic::Number do
  describe :read do
    it 'unsigned' do
      stream = StringIO.new("\xff" * 100)
      expect(MemoryIO::Types::Type.find(:u8).read(stream)).to eq 0xff
      expect(MemoryIO::Types::Type.find(:u16).read(stream)).to eq 0xffff
      expect(MemoryIO::Types::Type.find(:u32).read(stream)).to eq 0xffffffff
      expect(MemoryIO::Types::Type.find(:u64).read(stream)).to eq 0xffffffffffffffff
    end

    it 'signed' do
      stream = StringIO.new("\xff" * 100)
      expect(MemoryIO::Types::Type.find(:s8).read(stream)).to eq(-1)
      expect(MemoryIO::Types::Type.find(:s16).read(stream)).to eq(-1)
      expect(MemoryIO::Types::Type.find(:s32).read(stream)).to eq(-1)
      expect(MemoryIO::Types::Type.find(:s64).read(stream)).to eq(-1)
    end

    it 'floating' do
      stream = StringIO.new("\x00\x00\x80\xBF")
      expect(MemoryIO::Types::Type.find(:float).read(stream)).to eq(-1.0)
      stream = StringIO.new("\x00\x00\x00\x00\x00\x00\xF0\xBF")
      expect(MemoryIO::Types::Type.find(:double).read(stream)).to eq(-1.0)
    end
  end

  describe :write do
    it 'integer' do
      stream = StringIO.new
      MemoryIO::Types::Type.find(:u64).write(stream, 0xdeadbeef12345678)
      expect(stream.string).to eq "\x78\x56\x34\x12\xef\xbe\xad\xde"
      stream.string = ''
      MemoryIO::Types::Type.find(:s64).write(stream, -0x21524110edcba988)
      expect(stream.string).to eq "\x78\x56\x34\x12\xef\xbe\xad\xde"
    end

    it 'floating' do
      stream = StringIO.new
      MemoryIO::Types::Type.find(:float).write(stream, -0.123)
      expect(stream.string).to eq "m\xE7\xFB\xBD"
      stream.string = ''
      MemoryIO::Types::Type.find(:double).write(stream, -0.123)
      expect(stream.string).to eq "\xB0rh\x91\xED|\xBF\xBF"
    end
  end
end
