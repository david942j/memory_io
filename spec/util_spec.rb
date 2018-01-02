require 'memory_io/util'

describe MemoryIO::Util do
  it :underscore do
    expect(described_class.underscore('MemoryIO')).to eq 'memory_io'
    expect(described_class.underscore('MyModule::MyClass')).to eq 'my_module/my_class'
  end

  it :file_permission do
    expect(described_class.file_permission('not_exists/ala/zz')).to be nil

    s = described_class.file_permission('/proc/self/mem')
    expect(s.readable?).to be true
    expect(s.writable?).to be true

    s = described_class.file_permission('/proc/self/maps')
    expect(s.readable?).to be true
    expect(s.writable?).to be false

    # XXX: how to create a readable but fails-in-sysopen file?
    allow(File).to receive(:open) { raise Errno::EACCES }
    s = described_class.file_permission('/proc/self/mem')
    expect(s.readable?).to be false
    expect(s.writable?).to be false
  end

  it :safe_eval do
    expect(described_class.safe_eval('0xDEad - 57005')).to be 0
    expect(described_class.safe_eval('heap + 0x10 * pp', heap: 0xde00, pp: 8)).to be 0xde80
  end

  it :trim_libname do
    expect(described_class.trim_libname('libc-2.24.so')).to eq 'libc'
    expect(described_class.trim_libname('zlib.so')).to eq 'zlib'
    expect(described_class.trim_libname('libcrypto.so.1.0.0')).to eq 'libcrypto'
    expect(described_class.trim_libname('not_a_so')).to eq 'not_a_so'
    expect(described_class.trim_libname('cat.socat')).to eq 'cat.socat'
  end
end
