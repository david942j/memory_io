require 'ostruct'
require 'dentaku'

module MemoryIO
  # Defines utility methods.
  module Util
    module_function

    # Convert input into snake-case.
    #
    # This method also converts +'::'+ to +'/'+.
    #
    # @param [String] str
    #   String to be converted.
    #
    # @return [String]
    #   Converted string.
    #
    # @example
    #   Util.underscore('MemoryIO')
    #   #=> 'memory_io'
    #
    #   Util.underscore('MyModule::MyClass')
    #   #=> 'my_module/my_class'
    def underscore(str)
      return '' if str.empty?

      str = str.gsub('::', '/')
      str.gsub!(/([A-Z]+)([A-Z][a-z])/, '\1_\2')
      str.gsub!(/([a-z\d])([A-Z])/, '\1_\2')
      str.downcase!
      str
    end

    # @api private
    #
    # @param [String] file
    #   File name.
    #
    # @return [#readable?, #writable?, nil]
    #   Struct with two boolean method.
    #   +nil+ for file not exists or is inaccessible.
    def file_permission(file)
      return nil unless File.file?(file)

      stat = File.stat(file)
      # we do a trick here because /proc/[pid]/mem might be marked as readable but fails at sysopen.
      os = OpenStruct.new(readable?: stat.readable_real?, writable?: stat.writable_real?)
      begin
        os.readable? && File.open(file, 'rb').close
      rescue Errno::EACCES
        os[:readable?] = false
      end
      begin
        os.writable? && File.open(file, 'wb').close
      rescue Errno::EACCES
        os[:writable?] = false
      end
      os
    end

    # Evaluate string safely.
    #
    # @param [String] str
    #   String to be evaluated.
    # @param [{Symbol => Integer}] vars
    #   Predefined variables
    #
    # @return [Integer]
    #   Result.
    #
    # @example
    #   Util.safe_eval('heap + 0x10 * pp', heap: 0xde00, pp: 8)
    #   #=> 56960 # 0xde80
    def safe_eval(str, **vars)
      return str if str.is_a?(Integer)

      # dentaku 2 doesn't support hex
      str = str.gsub(/0x[0-9a-zA-Z]+/) { |c| c.to_i(16) }
      Dentaku::Calculator.new.store(vars).evaluate(str)
    end

    # Unpack a string into an integer.
    # Little endian is used.
    #
    # @param [String] str
    #   String.
    #
    # @return [Integer]
    #   Result.
    #
    # @example
    #   Util.unpack("\xff")
    #   #=> 255
    #   Util.unpack("@\xE2\x01\x00")
    #   #=> 123456
    def unpack(str)
      str.bytes.reverse.reduce(0) { |s, c| s * 256 + c }
    end

    # Pack an integer into +b+ bytes.
    # Little endian is used.
    #
    # @param [Integer] val
    #   The integer to pack.
    #   If +val+ contains more than +b+ bytes,
    #   only lower +b+ bytes in +val+ will be packed.
    #
    # @param [Integer] b
    #
    # @return [String]
    #   Packing result with length +b+.
    #
    # @example
    #   Util.pack(0x123, 4)
    #   #=> "\x23\x01\x00\x00"
    def pack(val, b)
      Array.new(b) { |i| (val >> (i * 8)) & 0xff }.pack('C*')
    end

    # Remove extension name (.so) and version in library name.
    #
    # @param [String] name
    #   Original library filename.
    #
    # @return [String]
    #   Name without version and '.so'.
    #
    # @example
    #   Util.trim_libname('libc-2.24.so')
    #   #=> 'libc'
    #   Util.trim_libname('libcrypto.so.1.0.0')
    #   #=> 'libcrypto'
    #   Util.trim_libname('not_a_so')
    #   #=> 'not_a_so'
    def trim_libname(name)
      type1 = '(-[\d.]+)?\.so$'
      type2 = '\.so.\d+[\d.]+$'
      name.sub(/#{type1}|#{type2}/, '')
    end
  end
end
