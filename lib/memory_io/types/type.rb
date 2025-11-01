# frozen_string_literal: true

require 'ostruct'

require 'memory_io/types/record'
require 'memory_io/util'

module MemoryIO
  module Types
    # The base class, all descendants of this class would be consider as a valid 'type'.
    class Type
      # The size of +size_t+. i.e. +sizeof(size_t)+.
      SIZE_T = 8

      class << self
        # Read {Type::SIZE_T} bytes and cast to a little endian unsigned integer.
        #
        # @param [#read] stream
        #   Stream to read.
        #
        # @return [Integer]
        #   Result.
        #
        # @example
        #   s = StringIO.new("\xEF\xBE\xAD\xDExV4\x00")
        #   Type.read_size_t(s).to_s(16)
        #   #=> '345678deadbeef'
        def read_size_t(stream)
          MemoryIO::Util.unpack(stream.read(SIZE_T))
        end

        # Pack +val+ into {Type::SIZE_T} bytes and write to +stream+.
        #
        # @param [#write] stream
        #   Stream to write.
        # @param [Integer] val
        #   Value to be written.
        #
        # @return [void]
        #
        # @example
        #   s = StringIO.new
        #   Type.write_size_t(s, 0x123)
        #   s.string
        #   #=> "\x23\x01\x00\x00\x00\x00\x00\x00"
        def write_size_t(stream, val)
          stream.write(MemoryIO::Util.pack(val, SIZE_T))
        end

        # Yield a block and resume the position of stream.
        #
        # @param [#pos, #pos=] stream
        #   Stream.
        # @param [Integer] pos
        #   Move +stream+'s position to +pos+ before invoke the block.
        #
        # @yieldparam [#pos, #pos=] stream
        #   Same as parameter +stream+.
        # @yieldreturn [Object]
        #   The returned object will be returned by this method.
        #
        # @return [Object]
        #   Returns the object returned by block.
        #
        # @example
        #   s = StringIO.new('1234')
        #   Type.keep_pos(s, pos: 2) { |s| s.read(2) }
        #   #=> '34'
        #   s.pos
        #   #=> 0
        def keep_pos(stream, pos: nil)
          org = stream.pos
          stream.pos = pos if pos
          ret = yield stream
          stream.pos = org
          ret
        end

        # @api private
        #
        # Find the subclass of {Type} by symbol.
        #
        # @param [Symbol] symbol
        #   Symbol that has been registered in {.register}.
        #
        # @return [{Symbol => Object}]
        #   The object that registered in {.register}.
        #
        # @see .register
        def find(symbol)
          @map[symbol]
        end

        # Register a new type.
        #
        # @param [#read, #write] object
        #   Normally, +object+ is a descendant class of {Type}.
        #
        # @option [Symbol, Array<Symbol>] alias
        #   Custom symbol name(s) that can be used in {.find}.
        # @option [String] doc
        #   Doc string that will be shown in README.md.
        #
        # @return [Array<Symbol>]
        #   Array of symbols that can be used for finding the registered object.
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
        #   Type.register(AnotherClass, alias: [:my_class, my_class2])
        #   #=> [:another_class, :my_class2]
        #
        # @note
        #   If all symbols in +alias+ have been registered, an ArgumentError will be raised.
        #   However, if at least one of aliases hasn't been used, registration will success.
        #
        # @see .find
        def register(object, option = {})
          @map ||= OpenStruct.new
          aliases = Array(option[:alias])
          reg_fail = ArgumentError.new(<<-EOS.strip)
Register '#{object.inspect}' fails because another object with same name has been registered.
Specify an alias such as `register(MyClass, alias: :custom_alias_name)`.
          EOS
          raise reg_fail if aliases.any? && aliases.all? { |ali| @map[ali] }

          keys = get_keys(object).concat(aliases).uniq.reject { |k| @map[k] }
          raise reg_fail if keys.empty?

          rec = MemoryIO::Types::Record.new(object, keys, option)
          keys.each { |k| @map[k] = rec }
        end

        # @abstract
        def read(_stream) raise NotImplementedError
        end

        # @abstract
        def write(_stream, _obj) raise NotImplementedError
        end

        private

        # @api private
        #
        # To record descendants.
        def inherited(klass)
          super
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
