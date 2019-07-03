# frozen_string_literal: true

require 'memory_io/types/record'

describe MemoryIO::Types::Record do
  it :obj do
    s = 'whatever'
    expect(described_class.new(s, []).obj).to be s
  end

  it :doc do
    record = described_class.new(nil, [], doc: 'docstring~')
    expect(record.doc).to eq 'docstring~'
    # @api private
    #
    # This is document!
    #
    # This should in the third line.
    #   Indent should be reserved.
    # And more
    #
    # @tags should be ignored
    record = described_class.new(nil, [], caller: OpenStruct.new(absolute_path: __FILE__, lineno: __LINE__))
    expect(record.doc).to eq <<-EOS
This is document!

This should in the third line.
  Indent should be reserved.
And more
    EOS
  end
end
