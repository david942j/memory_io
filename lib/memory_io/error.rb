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

  # Raised when an address expression cannot be evaluated.
  #
  # @example
  #   MemoryIO.attach('self').read('heep + 0x10', 4)
  #   # MemoryIO::InvalidAddressError: Failed to evaluate address: "heep + 0x10"
  class InvalidAddressError < Error; end

  # Raised when a value doesn't fit in the type it is written as.
  #
  # @example
  #   MemoryIO::IO.new(stream).write(0x100000041, as: :u32)
  #   # MemoryIO::ValueOutOfRangeError: 0x100000041 is out of range for 32-bit unsigned integer (0x0..0xffffffff)
  class ValueOutOfRangeError < Error; end
end
