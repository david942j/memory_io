module MemoryIO
  # Records information of a process.
  class Process
    # @api private
    # @return [#readable?, #writable?]
    attr_reader :perm

    # @api private
    #
    # Create process object from pid.
    #
    # @param [Integer] pid
    #   Process id.
    #
    # @note
    #   This class only supports procfs-based system. i.e. /proc is mounted and readable.
    #
    # @todo
    #   Support MacOS
    # @todo
    #   Support Windows
    def initialize(pid)
      @mem = "/proc/#{pid}/mem"
      # check permission of '/proc/pid/mem'
      @perm = MemoryIO::Util.file_permission(@mem)
      # TODO: raise custom exception
      raise Errno::ENOENT, @mem if perm.nil?
      # FIXME: use logger
      STDERR.puts(<<-EOS.strip) unless perm.readable? || perm.writable?
You have no permission to read/write this process.

Check the setting of /proc/sys/kernel/yama/ptrace_scope, or try
again as the root user.

To enable attach another process, do:

$ echo 0 | sudo tee /proc/sys/kernel/yama/ptrace_scope
      EOS
    end

    # Read from process's memory.
    #
    # This method has *almost* same arguements and return types as {IO#read}.
    # The only difference is this method needs parameter +addr+ (which
    # will be passed to paramter +from+ in {IO#reada}).
    #
    # @param [Integer, String] addr
    #   The address start to read.
    #   When String is given, it will be safe-evaluated.
    #   See examples.
    # @param [Integer] num_elements
    #   Number of elements to read. See {IO#read}.
    #
    # @return [String, Object, Array<Object>]
    #   See {IO#read}.
    #
    # @example
    #   process = MemoryIO.attach(`pidof victim`.to_i)
    #   puts process.read('heap', 4, as: :u64).map { |c| '0x%016x' % c }
    #   # 0x0000000000000000
    #   # 0x0000000000000021
    #   # 0x00000000deadbeef
    #   # 0x0000000000000000
    #   #=> nil
    #   process.read('heap+0x10', 4, as: :u8).map { |c| '0x%x' % c }
    #   #=> ['0xef', '0xbe', '0xad', '0xde']
    #
    # @see IO#read
    def read(addr, num_elements, **options)
      File.open(@mem, 'rb') do |f|
        MemoryIO::IO.new(f).read(num_elements, from: addr, **options)
      end
    end
  end
end
