module MemoryIO
  module Types
    # The base class, all descendents of this class would be consider as a valid 'type'.
    class Type
      class << self
        # Find the subclass of {Type} by symbol.
        #
        # @param [Symbol] symbol
        #   Symbol to be find.
        #
        # @return [#read, #write]
        #   The object that registered in {.register}.
        def find(symbol)
          @map[symbol]
        end

        # @api private
        #
        # @param [Symbol] symbol
        #   Symbol name that used for searching.
        # @param [#read, #write] klass
        #   Normally, +klass+ is a descendent of {Type}.
        #
        # @return [void]
        def register(symbol, klass)
          @map ||= {}
          @map[symbol] = klass
        end

        # @api private
        #
        # To record descendants.
        def inherited(klass)
          register(MemoryIO::Util.underscore(klass.name).to_sym, klass)
        end
      end
    end
  end
end
