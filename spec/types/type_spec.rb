require 'memory_io/types/type'

describe MemoryIO::Types::Type do
  it :read_size_t do
    s = StringIO.new("\xEF\xBE\xAD\xDExV4\x00")
    expect(described_class.read_size_t(s)).to eq 0x345678deadbeef
  end

  it :write_size_t do
    s = StringIO.new
    described_class.write_size_t(s, 0x123)
    expect(s.string).to eq "\x23\x01\x00\x00\x00\x00\x00\x00"
  end

  it :keep_pos do
    stream = StringIO.new('1234')
    expect(described_class.keep_pos(stream, pos: 2) { |s| s.read(2) }).to eq '34'
    expect(stream.pos).to be_zero
  end

  it :register do
    expect(described_class.register(Integer)).to eq [:integer]
    module MemoryIO
      module Types
        module MyModule
          class MyClass
          end
        end
      end
    end
    syms = described_class.register(MemoryIO::Types::MyModule::MyClass, alias: :meow)
    expect(syms).to eq %i[my_module/my_class my_class meow]
    expect { described_class.register(String, alias: :meow) }.to raise_error(ArgumentError, <<-EOS.strip)
Register 'String' fails because other objects with same name has been registered.
Specify an alias such as `register(MyClass, alias: :custom_alias_name)`.
    EOS
  end

  it :find do
    class A < MemoryIO::Types::Type
    end
    expect(described_class.find(:a).obj).to be A
  end
end
