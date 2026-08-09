# frozen_string_literal: true

require 'open3'

require 'memory_io/process'
require 'memory_io/types/types'

describe MemoryIO::Types::CPP::String do
  before(:all) do
    @launch = lambda do |&block|
      Open3.popen2(File.join(__dir__, '..', 'test_files', 'cpp', 'objects')) do |i, o, t|
        process = MemoryIO::Process.new(t.pid)
        block.call(i, o, process)
        i.close
      end
    end
  end

  it :record do
    record = MemoryIO::Types::Type.find(:string)
    expect(record.doc).to eq <<-EOS
The `std::string` class in C++11.

The std::string class can be seen as:
  class string {
    void* _M_dataplus;
    size_t string_length;
    union {
      char local_buf[15 + 1];
      size_t allocated_capacity;
    }
  };
    EOS
  end

  it :inspect do
    str = described_class.new('meow', 15, 0x00007fffdeadbeef).inspect
    expect(str).to eq '#<MemoryIO::Types::CPP::String @data="meow", @capacity=15, @dataplus=0x00007fffdeadbeef>'
  end

  it 'reads a string laid out unlike this host' do
    # dataplus and length are pointer sized, so a 32-bit string is 8 bytes shorter
    blob = lambda do |pack|
      head = [0x20, 26, 31].pack("#{pack}3") + ("\x00" * 12)
      "#{head.ljust(0x20, "\x00")}abcdefghijklmnopqrstuvwxyz\x00"
    end

    { 'L<' => :little, 'L>' => :big }.each do |pack, endian|
      io = MemoryIO::IO.new(StringIO.new(blob.call(pack)), pointer_size: 4, endian: endian)
      string = io.read(1, as: :'cpp/string')
      expect(string.data).to eq 'abcdefghijklmnopqrstuvwxyz'
      expect(string.capacity).to eq 31
      expect(string.dataplus).to eq 0x20
    end
  end

  it 'warns when data is set beyond capacity' do
    log = StringIO.new
    MemoryIO.logger = Logger.new(log, formatter: ->(_severity, _datetime, _progname, msg) { msg })
    str = described_class.new('meow', 15, 0)
    str.data = 'A' * 15
    expect(log.string).to be_empty
    str.data = 'A' * 16
    expect(log.string).to eq 'Length of str (16) is larger than capacity (15)'
  ensure
    MemoryIO.logger = nil
  end

  it :read do
    @launch.call do |_i, o, process|
      addrs = Array.new(3) { o.gets.to_i(16) }
      strings = addrs.map { |addr| process.read(addr, 1, as: :'cpp/string') }
      expect(strings.map(&:data)).to eq ['', 'AAAABBBBCCCCDDD', 'abcdefghijklmnopqrstuvwxyz']
      expect(strings.map(&:length)).to eq [0, 15, 26]
    end
  end

  it :write do
    s = StringIO.new
    MemoryIO::IO.new(s).write(described_class.new('meow', 15, 16))
    expect(s.string).to eq "\u0010#{"\x00" * 7}\u0004#{"\x00" * 7}meow\u0000"
    expect(s.pos).to eq 32
    @launch.call do |i, o, process|
      _, _, addr = Array.new(3) { o.gets.to_i(16) }
      string = process.read(addr, 1, as: :'cpp/string')
      expect(string.data).to eq 'abcdefghijklmnopqrstuvwxyz'
      string.data = 'A' * 26
      process.write(addr, string)
      i.puts
      expect(o.gets).to eq "#{'A' * 26}\n"
      string = process.read(addr, 1, as: :'cpp/string')
      expect(string.data).to eq 'A' * 26
    end
  end
end
