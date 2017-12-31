require 'memory_io/util'

describe MemoryIO::Util do
  it :underscore do
    expect(described_class.underscore('MemoryIO')).to eq 'memory_io'
    expect(described_class.underscore('MyModule::MyClass')).to eq 'my_class'
  end
end
