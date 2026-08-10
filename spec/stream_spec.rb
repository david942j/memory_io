# frozen_string_literal: true

require 'memory_io/context'
require 'memory_io/stream'

describe MemoryIO::Stream do
  before(:each) do
    @io = StringIO.new(+'abcdefgh')
    @stream = described_class.new(@io, MemoryIO::Context.new(endian: :big))
  end

  it 'carries the context' do
    expect(@stream.context.endian).to be :big
  end

  it 'behaves as the stream it wraps' do
    expect(@stream.read(3)).to eq 'abc'
    expect(@stream.pos).to eq 3
    @stream.pos = 0
    expect(@stream.read).to eq 'abcdefgh'
    @stream.pos = 0
    @stream.write('X')
    expect(@io.string).to eq 'Xbcdefgh'
  end

  it 'forwards everything else to the stream' do
    expect(@stream.respond_to?(:eof?)).to be true
    expect(@stream.eof?).to be false
    expect(@stream.size).to eq 8
    expect(@stream.read(100)).to eq 'abcdefgh'
    expect(@stream.eof?).to be true
  end

  it 'raises for a message the stream does not answer either' do
    expect(@stream.respond_to?(:no_such_method)).to be false
    expect { @stream.no_such_method }.to raise_error(NoMethodError)
  end
end
