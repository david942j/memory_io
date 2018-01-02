require 'memory_io/types/type'

describe MemoryIO::Types::Type do
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
