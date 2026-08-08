# frozen_string_literal: true

require 'logger'

# MemoryIO - Read/Write structures in memory.
module MemoryIO
  class << self
    # Diagnostics that are worth surfacing but don't stop the operation
    # are written here, so they can be silenced or redirected.
    #
    # @return [Logger]
    #   Defaults to a logger writing to +$stderr+.
    #
    # @example
    #   MemoryIO.logger.level = Logger::ERROR
    #
    #   MemoryIO.logger = Logger.new('memory_io.log')
    def logger
      @logger ||= ::Logger.new($stderr, progname: 'memory_io', formatter: FORMATTER)
    end

    attr_writer :logger
  end

  # @api private
  #
  # Keeps a message readable when it is shown to a human.
  #
  # @example
  #   # [memory_io] WARN: something happened
  FORMATTER = proc { |severity, _datetime, progname, msg| "[#{progname}] #{severity}: #{msg}\n" }
end
