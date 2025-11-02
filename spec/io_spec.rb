# encoding: ascii-8bit
# frozen_string_literal: true

require 'memory_io/io'

describe MemoryIO::IO do
  describe 'read' do
    before(:all) do
      @get_io = ->(str) { MemoryIO::IO.new(StringIO.new(str)) }
    end

    it 'basic' do
      io = @get_io.call('abcdefgh01234567')
      expect(io.read(8)).to eq 'abcdefgh'
      expect(io.read(10)).to eq '01234567'
      expect(io.read(10, from: 2)).to eq 'cdefgh0123'
      io.rewind
      expect(io.read(10)).to eq 'abcdefgh01'
    end

    it 'proc' do
      io = @get_io.call("\x03123\x044567")
      expect(io.read(2, as: ->(stream) { stream.read(stream.read(1).ord) })).to eq %w[123 4567]
    end

    it 'symbolic as' do
      io = @get_io.call("AAAABBBB\xef\xbe\xad\xde\x00\x00\x00\x00")
      expect(io.read(2, as: :u64)).to eq [0x4242424241414141, 0xdeadbeef]
      expect(io.read(1, from: 0, as: :u64, force_array: true)).to eq [0x4242424241414141]
      expect(io.read(1, from: 8, as: :u32)).to eq 0xdeadbeef
      expect(io.read(1, from: 8, as: :s32)).to eq 0xdeadbeef - (2**32)

      io = @get_io.call("123\x0045678\x00")
      expect(io.read(2, as: :c_str)).to eq %w[123 45678]
    end
  end

  describe :write do
    it 'basic' do
      stream = StringIO.new.binmode
      io = MemoryIO::IO.new(stream)
      io.write('abcd')
      expect(stream.string).to eq 'abcd'
      io.write([1, 2, 3, 4], from: 2, as: :u16)
      expect(stream.string).to eq "ab\x01\x00\x02\x00\x03\x00\x04\x00"
      io.write(%w[A BB CCC], from: 0, as: :c_str)
      expect(stream.string).to eq "A\x00BB\x00CCC\x00\x00"
    end

    it 'proc' do
      stream = StringIO.new.binmode
      io = MemoryIO::IO.new(stream)
      io.write(%w[123 4567], as: ->(s, str) { s.write(str.size.chr + str) })
      expect(stream.string).to eq "\x03123\x044567"
    end
  end
end
