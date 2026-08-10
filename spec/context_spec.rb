# frozen_string_literal: true

require 'memory_io/context'

describe MemoryIO::Context do
  it 'resolves native to the byte order of the host' do
    expect(described_class.new.endian).to eq described_class::NATIVE_ENDIAN
    expect(described_class.new(endian: :native).endian).to eq described_class::NATIVE_ENDIAN
    expect(described_class::NATIVE_ENDIAN).to eq([1].pack('S') == "\x01\x00".b ? :little : :big)
  end

  it 'keeps an explicit byte order' do
    expect(described_class.new(endian: :little).endian).to be :little
    expect(described_class.new(endian: :big).endian).to be :big
  end

  it 'rejects an unknown byte order' do
    expect { described_class.new(endian: :middle) }.to \
      raise_error(ArgumentError, 'endian must be one of [:little, :big, :native], got :middle')
  end

  it 'defaults the pointer size' do
    expect(described_class.new.pointer_size).to eq described_class::DEFAULT_POINTER_SIZE
    expect(described_class.new(pointer_size: 4).pointer_size).to eq 4
  end

  it 'of returns the context a stream was tagged with' do
    context = described_class.new(endian: :big)
    stream = MemoryIO::Stream.new(StringIO.new, context)
    expect(described_class.of(stream)).to be context
  end

  it 'of falls back to the default for an untagged stream' do
    expect(described_class.of(StringIO.new)).to be described_class.default
    expect(described_class.default.endian).to eq described_class::NATIVE_ENDIAN
  end
end
