require 'ostruct'

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
  end
end
