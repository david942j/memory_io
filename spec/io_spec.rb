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

    it 'rejects a num_elements that cannot be read' do
      io = @get_io.call('AAAA')
      [-1, 2.5, nil].each do |bad|
        expect { io.read(bad, as: :u8) }.to \
          raise_error(ArgumentError, "num_elements must be a non-negative Integer, got #{bad.inspect}")
        expect { io.read(bad) }.to raise_error(ArgumentError)
      end
    end

    it 'reads nothing when asked for nothing' do
      io = @get_io.call('AAAA')
      expect(io.read(0)).to eq ''
      expect(io.read(0, as: :u8)).to eq []
      expect(io.stream.pos).to be_zero
    end

    it 'returns the objects read before eof' do
      io = @get_io.call("\x01\x02\x03\x04")
      expect(io.read(3, as: :u32)).to eq [0x04030201]

      io.rewind
      expect(io.read(2, as: :s32)).to eq [0x04030201]

      io.rewind
      expect(io.read(4, as: :c_str)).to eq ["\x01\x02\x03\x04"]
    end

    it 'omits an object that cannot be read in full' do
      io = @get_io.call("\x01\x02\x03\x04")
      expect(io.read(1, as: :u64)).to be nil
      io.rewind
      expect(io.read(1, as: :u64, force_array: true)).to eq []
      io.rewind
      expect(io.read(1, as: :string)).to be nil
    end

    it 'returns an empty array when the stream is exhausted' do
      io = @get_io.call('')
      expect(io.read(2, as: :u32)).to eq []
      expect(io.read(2, as: :c_str)).to eq []
      expect(io.read(1, as: :u8)).to be nil
    end

    it 'detects eof on a stream that has no eof?' do
      minimal = Class.new do
        def initialize(str)
          @io = StringIO.new(str)
        end

        def pos
          @io.pos
        end

        def pos=(val)
          @io.pos = val
        end

        def read(*args)
          @io.read(*args)
        end
      end
      io = MemoryIO::IO.new(minimal.new("\x01\x02\x03\x04"))
      expect(io.read(3, as: :u32)).to eq [0x04030201]
      io.rewind
      expect(io.read(2, as: :u16)).to eq [0x0201, 0x0403]
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
