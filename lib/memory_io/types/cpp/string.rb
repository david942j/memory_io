# frozen_string_literal: true

require 'memory_io/context'
require 'memory_io/logger'
require 'memory_io/types/type'
require 'memory_io/util'

module MemoryIO
  module Types
    # Structures in C++.
    module CPP
      # The `std::string` class in C++11.
      #
      # The std::string class can be seen as:
      #   class string {
      #     void* _M_dataplus;
      #     size_t string_length;
      #     union {
      #       char local_buf[15 + 1];
      #       size_t allocated_capacity;
      #     }
      #   };
      class String < MemoryIO::Types::Type

        # std::string uses inlined-buffer if string length isn't larger than {LOCAL_CAPACITY}.
        LOCAL_CAPACITY = 15

        attr_reader :data, :capacity, :dataplus # @return [::String] # @return [Integer] # @return [Integer]

        # Instantiate a {CPP::String} object.
        #
        # @param [::String] data
        # @param [Integer] capacity
        # @param [Integer] dataplus
        #   A pointer.
        def initialize(data, capacity, dataplus)
          super()
          @data = data
          @capacity = capacity
          @dataplus = dataplus
        end

        # String length.
        #
        # @return [Integer]
        def length
          @data.size
        end
        alias size length

        # Set data content.
        #
        # @param [String] str
        def data=(str)
          @data = str
          return unless str.size > capacity

          MemoryIO.logger.warn("Length of str (#{str.size}) is larger than capacity (#{capacity})")
        end

        # Custom inspect view.
        #
        # @return [String]
        def inspect
          format('#<%s @data=%s, @capacity=%d, @dataplus=0x%s>',
                 self.class.name,
                 data.inspect,
                 capacity,
                 dataplus.to_s(16).rjust(SIZE_T * 2, '0'))
        end

        class << self
          # @param [#pos, #pos=, #read] stream
          #
          # @return [CPP::String]
          #
          # @raise [EOFError]
          #   The object is incomplete, or its characters cannot be read from
          #   where it points. {MemoryIO::IO#read} answers with the objects it
          #   read in full rather than one that is partly filled in.
          #
          # @example
          #   # echo '#include <string>\n#include <cstdio>\nint main() {' > a.cpp && \
          #   # echo 'std::string a="abcd"; printf("%p\\n", &a);' >> a.cpp && \
          #   # echo 'scanf("%*c"); return 0;}' >> a.cpp && \
          #   # g++ -std=c++11 a.cpp -o a
          #   Open3.popen2('stdbuf -o0 ./a') do |_i, o, t|
          #     process = MemoryIO.attach(t.pid)
          #     addr = o.gets.to_i(16)
          #     process.read(addr, 1, as: :string) # or `as: :'cpp/string'`
          #     #=> #<MemoryIO::Types::CPP::String @data="abcd", @capacity=15, @dataplus=0x00007ffe539ca250>
          #   end
          def read(stream)
            dataplus = read_size_t(stream)
            length = read_size_t(stream)
            union = MemoryIO::Util.read_exactly(stream, LOCAL_CAPACITY + 1)
            if length > LOCAL_CAPACITY
              context = MemoryIO::Context.of(stream)
              capacity = MemoryIO::Util.unpack(union[0, context.pointer_size], context.endian)
              data = keep_pos(stream, pos: dataplus) { |s| MemoryIO::Util.read_exactly(s, length) }
            else
              capacity = LOCAL_CAPACITY
              data = union[0, length]
            end
            new(data, capacity, dataplus)
          end

          # Write a {CPP::String} object to stream.
          #
          # @param [#pos, #pos=, #write] stream
          # @param [CPP::String] obj
          #
          # @return [void]
          def write(stream, obj)
            write_size_t(stream, obj.dataplus)
            write_size_t(stream, obj.length)
            pos = stream.pos
            if obj.length > LOCAL_CAPACITY
              keep_pos(stream, pos: obj.dataplus) { |s| s.write("#{obj.data}\u0000") }
              write_size_t(stream, obj.capacity)
            else
              stream.write("#{obj.data}\u0000")
            end
            stream.pos = pos + LOCAL_CAPACITY + 1
          end
        end
      end
    end
  end
end
