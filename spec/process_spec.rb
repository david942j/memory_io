# encoding: ascii-8bit
# frozen_string_literal: true

require 'rubygems'

require 'memory_io/process'

describe MemoryIO::Process do
  it 'raises when the process is not accessible' do
    expect { described_class.new(0) }.to \
      raise_error(MemoryIO::ProcessNotFoundError, '/proc/0/mem does not exist')
    expect { described_class.new(0) }.to raise_error(MemoryIO::Error)
  end

  it 'raises when the address cannot be evaluated' do
    process = described_class.new('self')
    expect { process.read('heep + 0x10', 4) }.to \
      raise_error(MemoryIO::InvalidAddressError, 'Failed to evaluate address: "heep + 0x10"')
    expect { process.write('((((', 'A') }.to raise_error(MemoryIO::InvalidAddressError)
    expect { process.read('0xzz', 4) }.to raise_error(MemoryIO::Error)
  end

  it :initialize do
    allow(File).to receive(:open) { raise Errno::EACCES }
    log = StringIO.new
    MemoryIO.logger = Logger.new(log, formatter: ->(_severity, _datetime, _progname, msg) { msg })
    described_class.new('self')
    expect(log.string).to eq <<-EOS.strip
You have no permission to read/write this process.

Check the setting of /proc/sys/kernel/yama/ptrace_scope, or try
again as the root user.

To enable attach another process, do:

$ echo 0 | sudo tee /proc/sys/kernel/yama/ptrace_scope
    EOS
  ensure
    MemoryIO.logger = nil
  end

  it 'takes its context from the target executable' do
    process = described_class.new('self')
    expect(process.context.to_h).to eq MemoryIO::Context.from_elf('/proc/self/exe').to_h
  end

  it 'lets the caller override the detected context' do
    process = described_class.new('self', endian: :big, pointer_size: 4)
    expect(process.context.to_h).to eq(endian: :big, pointer_size: 4)
  end

  it 'falls back to this host when the executable cannot be read' do
    allow(MemoryIO::Context).to receive(:from_elf).and_return(nil)
    expect(described_class.new('self').context.to_h).to eq MemoryIO::Context.new.to_h
  end

  it :bases do
    process = described_class.new('self')
    expect(process.bases.keys).to include(:libc, :heap, :ruby, :ld, :stack)
    expect(process.bases.values.map { |v| v & 0xfff }.uniq).to eq [0]
  end

  it :read do
    process = described_class.new('self')
    expect(process.read('ruby+0', 4)).to eq "\x7fELF"
  end

  it :write do
    process = described_class.new('self')
    was = process.read('ruby+0', 4)
    process.write('ruby + 0', 'ABCD')
    expect(process.read('ruby+0', 4)).to eq 'ABCD'
    process.write('ruby + 0', was)
  end

  it 'resolves an integer address without parsing maps' do
    process = described_class.new('self')
    addr = process.bases[:ruby]
    expect(process).not_to receive(:bases)
    expect(process.read(addr, 4)).to eq "\x7fELF"
    was = process.read(addr, 4)
    process.write(addr, 'ABCD')
    expect(process.read(addr, 4)).to eq 'ABCD'
    process.write(addr, was)
  end

  it 'use custom type' do
    process = described_class.new('self')

    class MyType < MemoryIO::Types::Type
      def self.read(stream)
        new(stream.read(1))
      end

      def self.write(stream, my_type)
        stream.write(my_type.val)
      end

      attr_accessor :val

      def initialize(val)
        @val = val
      end
    end

    expect(process.read('libc', 4, as: :my_type).map(&:val)).to eq ["\x7f", 'E', 'L', 'F']

    process.write('libc', MyType.new('MEOW'), as: MyType)
    expect(process.read('libc', 4)).to eq 'MEOW'
  end
end
