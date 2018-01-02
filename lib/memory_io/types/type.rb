require 'ostruct'

require 'memory_io/types/record'

module MemoryIO
  module Types
    # The base class, all descendents of this class would be consider as a valid 'type'.
    class Type
      class << self
        # @api private
        #
        # Find the subclass of {Type} by symbol.
        #
        # @param [Symbol] symbol
        #   Symbol that has been registered in {.register}.
        #
        # @return [{Symbol => Object}]
        #   The object that registered in {.register}.
        def find(symbol)
          @map[symbol]
        end

        # Register a new type.
        #
        # @param [#read, #write] object
        #   Normally, +object+ is a descendent class of {Type}.
        #
        # @option [Symbol] alias
        #   Custom symbol name that can be used in {.find}.
        # @option [String] doc
        #   Doc string that will be shown in README.md.
        #
        # @return [Array<Symbol>]
        #   Array of symbols that can be used for finding the registered object.
        #   See {.find}.
        #
        # @example
        #   Type.register(MemoryIO::Types::Clang::CStr, alias: :meow)
        #   #=> [:'clang/c_str', :c_str, :meow]
        #
        #   Type.register(ModuleOne::CStr, alias: :my_class)
        #   #=> [:'module_one/c_str', :my_class]
        #
        #   Type.register(AnotherClass, alias: :my_class)
        #   # An error will be raised because the 'alias' has been registered.
        #
        # @see .find
        def register(object, option = {})
          @map ||= OpenStruct.new
          ali = option[:alias]
          reg_fail = ArgumentError.new(<<-EOS.strip)
Register '#{object.inspect}' fails because other objects with same name has been registered.
Specify an alias such as `register(MyClass, alias: :custom_alias_name)`.
          EOS
          raise reg_fail if ali && @map[ali]
          keys = get_keys(object).reject { |k| @map[k] }
          keys << ali if ali
          raise reg_fail if keys.empty?
          rec = MemoryIO::Types::Record.new(object, keys, option)
          keys.each { |k| @map[k] = rec }
        end

        private

        # @api private
        #
        # To record descendants.
        def inherited(klass)
          register(klass, caller: caller_locations(1, 1).first)
        end

        # @param [Class] klass
        #
        # @return [Array<Symbol>]
        def get_keys(klass)
          return [] unless klass.instance_of?(Class)
          snake = MemoryIO::Util.underscore(klass.name)
          snake.gsub!(%r[^memory_io/types/], '')
          ret = [snake]
          ret << ::File.basename(snake)
          ret.map(&:to_sym).uniq
        end
      end
    end
  end
end
