require 'ostruct'
require 'dentaku'

module MemoryIO
  # Defines utility methods.
  module Util
    module_function

    # Convert input into snake-case.
    #
    # This method also removes strings before +'::'+ in +str+.
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
    #   #=> 'my_class'
    def underscore(str)
      return '' if str.empty?
      str = str.split('::').last
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
