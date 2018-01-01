require 'memory_io/util'

describe MemoryIO::Util do
  it :underscore do
    expect(described_class.underscore('MemoryIO')).to eq 'memory_io'
    expect(described_class.underscore('MyModule::MyClass')).to eq 'my_class'
  end

  it :file_permission do
    expect(described_class.file_permission('not_exists/ala/zz')).to be nil
    s = described_class.file_permission('/proc/self/mem')
    expect(s.readable?).to be true
    expect(s.writable?).to be true
    # XXX: how to create a readable but fails-in-sysopen file?
    allow(File).to receive(:open) { raise Errno::EACCES }
    s = described_class.file_permission('/proc/self/mem')
    expect(s.readable?).to be false
    expect(s.writable?).to be false
  end
end
