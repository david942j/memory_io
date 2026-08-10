# encoding: ascii-8bit
# frozen_string_literal: true

require 'memory_io/types/clang/c_str'

describe MemoryIO::Types::Clang::CStr do
  it 'read' do
    stream = StringIO.new("abcd\x00kk\x00\x00end_of_string")
    expect(Array.new(4) { described_class.read(stream) }).to eq ['abcd', 'kk', '', 'end_of_string']
  end

  it 'reads a string longer than one chunk' do
    size = described_class::CHUNK_SIZE
    stream = StringIO.new("#{'A' * ((size * 2) + 3)}\x00tail\x00")
    expect(described_class.read(stream)).to eq 'A' * ((size * 2) + 3)
    expect(described_class.read(stream)).to eq 'tail'
  end

  it 'reads a terminator sitting on a chunk boundary' do
    size = described_class::CHUNK_SIZE
    # terminator as the last byte of the first chunk, and as the first byte of the second
    [size - 1, size].each do |offset|
      stream = StringIO.new("#{'A' * offset}\x00next\x00")
      expect(described_class.read(stream)).to eq 'A' * offset
      expect(described_class.read(stream)).to eq 'next'
    end
  end

  it 'returns what was read when the stream ends without a terminator' do
    stream = StringIO.new('no terminator')
    expect(described_class.read(stream)).to eq 'no terminator'
    expect(described_class.read(stream)).to eq ''
  end

  it 'write' do
    stream = StringIO.new
    described_class.write(stream, '123')
    expect(stream.string).to eq "123\x00"
  end

  it 'doc' do
    expect(MemoryIO::Types::Type.find(:c_str).doc).to eq "A null-terminated string.\n"
  end
end
