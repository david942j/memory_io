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
  # @param [:little, :big, :native, nil] endian
  #   Byte order of the process's memory.
  # @param [Integer?] pointer_size
  #   Size of a pointer in the process, in bytes.
  #
  #   Both are taken from the process's executable when not given.
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
  # @example
  #   # a program started through an interpreter is described by the
  #   # interpreter, so state the context of the program instead
  #   MemoryIO.attach(`pidof victim32`.to_i, pointer_size: 4)
  #
  # @note
  #   The context is read from +/proc/[pid]/exe+, which names the interpreter
  #   when the process was started through one. Pass +endian+ and
  #   +pointer_size+ for such a process, whose context may differ from
  #   the interpreter running it.
  # @see MemoryIO::Process#initialize
  def attach(pid, endian: nil, pointer_size: nil)
    MemoryIO::Process.new(pid, endian: endian, pointer_size: pointer_size)
  end
end

require 'memory_io/io'
require 'memory_io/process'
require 'memory_io/version'
