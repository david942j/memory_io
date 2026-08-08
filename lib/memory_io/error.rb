# frozen_string_literal: true

module MemoryIO
  # The base class of all errors raised by {MemoryIO}.
  #
  # Rescue this class to catch every error this library raises on its own.
  # Errors that propagate from Ruby itself are not covered.
  #
  # @example
  #   begin
  #     MemoryIO.attach(0)
  #   rescue MemoryIO::Error => e
  #     puts e.message
  #   end
  #   # /proc/0/mem does not exist
  class Error < StandardError; end

  # Raised when the memory of the target process is not accessible.
  #
  # @example
  #   MemoryIO.attach(0)
  #   # MemoryIO::ProcessNotFoundError: /proc/0/mem does not exist
  class ProcessNotFoundError < Error; end
end
