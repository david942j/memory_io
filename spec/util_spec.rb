# frozen_string_literal: true

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

    # a file that is marked readable but fails at sysopen, as /proc/[pid]/mem can
    allow(File).to receive(:open) { raise Errno::EACCES }
    s = described_class.file_permission('/proc/self/mem')
    expect(s.readable?).to be false
    expect(s.writable?).to be false
  end

  it :read_exactly do
    stream = StringIO.new('1234')
    expect(described_class.read_exactly(stream, 3)).to eq '123'
    expect { described_class.read_exactly(stream, 2) }.to \
      raise_error(EOFError, 'Requires 0x2 bytes, but only 0x1 bytes remain')
    expect { described_class.read_exactly(stream, 1) }.to \
      raise_error(EOFError, 'Requires 0x1 bytes, but only 0x0 bytes remain')
  end

  it :safe_eval do
    expect(described_class.safe_eval('0xDEad - 57005')).to be 0
    expect(described_class.safe_eval('heap + 0x10 * pp', heap: 0xde00, pp: 8)).to be 0xde80
    expect(described_class.safe_eval(0xdead)).to be 0xdead
  end

  it 'safe_eval rejects an invalid expression' do
    expect(described_class.safe_eval('0xzz')).to be nil
    expect(described_class.safe_eval('0xzz + 1')).to be nil
    expect(described_class.safe_eval('unknown_var + 1')).to be nil
  end

  it :trim_libname do
    expect(described_class.trim_libname('libc-2.24.so')).to eq 'libc'
    expect(described_class.trim_libname('zlib.so')).to eq 'zlib'
    expect(described_class.trim_libname('libcrypto.so.1.0.0')).to eq 'libcrypto'
    expect(described_class.trim_libname('not_a_so')).to eq 'not_a_so'
    expect(described_class.trim_libname('cat.socat')).to eq 'cat.socat'
    expect(described_class.trim_libname('libc.so.6')).to eq 'libc'
    expect(described_class.trim_libname('libm.so.6')).to eq 'libm'
    expect(described_class.trim_libname('libgcc_s.so.1')).to eq 'libgcc_s'
    expect(described_class.trim_libname('ld-linux-x86-64.so.2')).to eq 'ld'
  end
end
