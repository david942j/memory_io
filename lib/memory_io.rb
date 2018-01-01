# MemoryIO - Read/Write structures in memory.
#
# @author david942j
module MemoryIO
  module_function

  # Get a process by process id.
  #
  # @param [Integer] pid
  #   Process Id in linux.
  #
  # @return [MemoryIO::Process]
  #   A process object for further usage.
  def attach(pid)
    MemoryIO::Process.new(pid)
  end
end

require 'memory_io/io'
require 'memory_io/process'
require 'memory_io/version'
