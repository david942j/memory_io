# encoding: ascii-8bit

require 'memory_io/types/c_str'

describe MemoryIO::Types::CStr do
  it 'read' do
    stream = StringIO.new("abcd\x00kk\x00\x00end_of_string")
    expect(Array.new(4) { described_class.read(stream) }).to eq ['abcd', 'kk', '', 'end_of_string']
  end

  it 'write' do
    stream = StringIO.new
    described_class.write(stream, '123')
    expect(stream.string).to eq "123\x00"
  end
end
