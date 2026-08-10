# frozen_string_literal: true

# MemoryIO - Read/Write structures in memory.
#
# @author david942j
module MemoryIO
  module_function

  # Get a process by process id.
  #
  # @param [Integer] pid
  #   Process id in Linux.
  #
  # @return [MemoryIO::Process]
  #   A process object for further usage.
  #
  # @raise [MemoryIO::ProcessNotFoundError]
  #   The memory of +pid+ is not accessible.
  #
  # @example
  #   process = MemoryIO.attach(`pidof victim`.to_i)
  #   process.read('heap', 8)
  def attach(pid)
    MemoryIO::Process.new(pid)
  end
end

require 'memory_io/io'
require 'memory_io/process'
require 'memory_io/version'
