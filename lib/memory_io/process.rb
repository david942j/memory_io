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
      @pid = pid
      @mem = "/proc/#{pid}/mem"
      # check permission of '/proc/pid/mem'
      @perm = MemoryIO::Util.file_permission(@mem)
      # TODO: raise custom exception
      raise Errno::ENOENT, @mem if perm.nil?
      # FIXME: use logger
      warn(<<-EOS.strip) unless perm.readable? || perm.writable?
You have no permission to read/write this process.

Check the setting of /proc/sys/kernel/yama/ptrace_scope, or try
again as the root user.

To enable attach another process, do:

$ echo 0 | sudo tee /proc/sys/kernel/yama/ptrace_scope
      EOS
    end

    # Parse +/proc/[pid]/maps+ to get all bases.
    #
    # @return [{Symbol => Integer}]
    #   Hash of bases.
    #
    # @example
    #   process = Process.new(`pidof victim`.to_i)
    #   puts process.bases.map { |key, val| format('%s: 0x%016x', key, val) }
    #   # vsyscall: 0xffffffffff600000
    #   # vdso: 0x00007ffd5b565000
    #   # vvar: 0x00007ffd5b563000
    #   # stack: 0x00007ffd5ad21000
    #   # ld: 0x00007f339a69b000
    #   # libc: 0x00007f33996f1000
    #   # heap: 0x00005571994a1000
    #   # victim: 0x0000557198bcb000
    #   #=> nil
    def bases
      file = "/proc/#{@pid}/maps"
      stat = MemoryIO::Util.file_permission(file)
      return {} unless stat && stat.readable?
      maps = ::IO.binread(file).split("\n").map do |line|
        # 7f76515cf000-7f76515da000 r-xp 00000000 fd:01 29360257  /lib/x86_64-linux-gnu/libnss_files-2.24.so
        addr, _perm, _offset, _dev, _inode, pathname = line.strip.split(' ', 6)
        next nil if pathname.nil?
        addr = addr.to_i(16)
        pathname = pathname[1..-2] if pathname =~ /^\[.+\]$/
        pathname = ::File.basename(pathname)
        [MemoryIO::Util.trim_libname(pathname).to_sym, addr]
      end
      maps.compact.reverse.to_h
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
    #   You can use variables such as +'heap'/'stack'/'libc'+ in this parameter.
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
    #   process.read('libc', 4)
    #   #=> "\x7fELF"
    # @see IO#read
    def read(addr, num_elements, **options)
      addr = MemoryIO::Util.safe_eval(addr, bases)
      File.open(@mem, 'rb') do |f|
        MemoryIO::IO.new(f).read(num_elements, from: addr, **options)
      end
    end
  end
end
