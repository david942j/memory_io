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
  end
end
