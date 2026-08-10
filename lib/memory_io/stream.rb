# frozen_string_literal: true

module MemoryIO
  # @api private
  #
  # A stream tagged with the {Context} of the memory it accesses.
  #
  # Types are handed one of these instead of the bare stream, so that a type
  # can learn how to interpret the bytes it reads without the reading
  # interface having to grow another argument.
  #
  # Every other message is forwarded, so a stream behaves as it did before.
  class Stream
    # @return [MemoryIO::Context]
    attr_reader :context

    # @param [#read, #write] stream
    #   The stream to be tagged.
    # @param [MemoryIO::Context] context
    #   The context of the memory reached through +stream+.
    def initialize(stream, context)
      @stream = stream
      @context = context
    end

    def read(*)
      @stream.read(*)
    end

    def write(*)
      @stream.write(*)
    end

    def pos
      @stream.pos
    end

    def pos=(val)
      @stream.pos = val
    end

    private

    def method_missing(name, *, &)
      return super unless @stream.respond_to?(name)

      @stream.public_send(name, *, &)
    end

    def respond_to_missing?(name, include_private = false)
      @stream.respond_to?(name, include_private) || super
    end
  end
end
