require 'memory_io/types/type'
require 'memory_io/util'

require 'memory_io/types/c_str'
require 'memory_io/types/number'

module MemoryIO
  # Module that includes multiple types.
  #
  # Supported types are all descendants of {Types::Type}.
  module Types
    module_function

    # @api private
    #
    # Returns the class whose name matches +name+.
    #
    # This method will search all descendants of {Types::Type}.
    #
    # @return [Symbol] name
    #   Class name to be searched.
    #
    # @return [#read, #write]
    #   Any object that implemented method +read+ and +write+.
    #   Usually returns a class inherit {Types::Type}.
    #
    # @example
    #   Types.find(:c_str)
    #   #=> MemoryIO::Types::CStr
    #
    #   Types.find(:u64)
    #   #=> #<MemoryIO::Types::Number:0x000055ecc017a310 @bytes=8, @pack_str="Q", @signed=false>
    def find(name)
      Types::Type.find(Util.underscore(name.to_s).to_sym)
    end

    # @api private
    #
    # Returns a callable object according to +name+.
    #
    # @param [Symbol] name
    #   The name of type.
    # @param [:read, :write] rw
    #   Read or write?
    #
    # @return [Proc?]
    #   The proc that accepts +stream+ as the first parameter.
    #
    # @example
    #   Types.get_proc(:c_str, :write)
    #   #=> #<Method: MemoryIO::Types::CStr.write>
    #   Types.get_proc(:s32, :read)
    #   #=> #<Method: MemoryIO::Types::Number#read>
    def get_proc(name, rw)
      klass = find(name)
      klass && klass.method(rw)
    end
  end
end
