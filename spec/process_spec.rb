# encoding: ascii-8bit
# frozen_string_literal: true

require 'rubygems'

require 'memory_io/process'

describe MemoryIO::Process do
  let(:before_2_7) { Gem::Version.new(RUBY_VERSION) < Gem::Version.new('2.7') }

  it :initialize do
    allow(File).to receive(:open) { raise Errno::EACCES }
    expect { described_class.new('self') }.to output(<<-EOS).to_stderr
You have no permission to read/write this process.

Check the setting of /proc/sys/kernel/yama/ptrace_scope, or try
again as the root user.

To enable attach another process, do:

$ echo 0 | sudo tee /proc/sys/kernel/yama/ptrace_scope
    EOS
  end

  it :bases do
    process = described_class.new('self')
    expect(process.bases.keys).to include(:libc, :heap, :ruby, :ld, :stack)
    expect(process.bases.values.map { |v| v & 0xfff }.uniq).to eq [0]
  end

  it :read do
    process = described_class.new('self')
    expect(process.read('ruby+0', 4)).to eq "\x7fELF"
    next unless before_2_7

    s = 'A' * 10
    expect(process.read(s.__id__ * 2 + 16, 2, as: :u64)).to eq [0x4141414141414141, 0x4141]
  end

  it :write do
    process = described_class.new('self')
    was = process.read('ruby+0', 4)
    process.write('ruby + 0', 'ABCD')
    expect(process.read('ruby+0', 4)).to eq "ABCD"
    process.write('ruby + 0', was)
    next unless before_2_7

    s = 'A' * 16
    process.write(s.__id__ * 2 + 16, [1, 2, 3, 4], as: :u8)
    expect(s).to eq "\x01\x02\x03\x04AAAAAAAAAAAA"
    process.write(s.__id__ * 2 + 16, 'abcdefgh')
    expect(s).to eq 'abcdefghAAAAAAAA'
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
