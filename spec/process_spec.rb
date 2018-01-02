# encoding: ascii-8bit

require 'memory_io/process'

describe MemoryIO::Process do
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
    s = 'A' * 10
    expect(process.read(s.__id__ * 2 + 16, 2, as: :u64)).to eq [0x4141414141414141, 0x4141]
  end

  it :write do
    process = described_class.new('self')
    s = 'A' * 16
    process.write(s.__id__ * 2 + 16, [1, 2, 3, 4], as: :u8)
    expect(s).to eq "\x01\x02\x03\x04AAAAAAAAAAAA"
    process.write(s.__id__ * 2 + 16, 'abcdefgh')
    expect(s).to eq 'abcdefghAAAAAAAA'
  end
end
