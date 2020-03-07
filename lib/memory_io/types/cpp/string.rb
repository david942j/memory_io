# frozen_string_literal: true

require 'memory_io/types/type'

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

        attr_reader :data # @return [::String]
        attr_reader :capacity # @return [Integer]
        attr_reader :dataplus # @return [Integer]

        # Instantiate a {CPP::String} object.
        #
        # @param [::String] data
        # @param [Integer] capacity
        # @param [Integer] dataplus
        #   A pointer.
        def initialize(data, capacity, dataplus)
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
          warn("Length of str (#{str.size}) is larger than capacity (#{capacity})") if str.size > capacity
        end

        # Custom inspect view.
        #
        # @return [String]
        #
        # @todo
        #   Let it be colorful in pry.
        def inspect
          format("#<%s @data=%s, @capacity=%d, @dataplus=0x%0#{SIZE_T * 2}x>",
                 self.class.name,
                 data.inspect,
                 capacity,
                 dataplus)
        end

        class << self
          # @param [#pos, #pos=, #read] stream
          #
          # @return [CPP::String]
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
            union = stream.read(LOCAL_CAPACITY + 1)
            if length > LOCAL_CAPACITY
              capacity = MemoryIO::Util.unpack(union[0, Type::SIZE_T])
              data = keep_pos(stream, pos: dataplus) { |s| s.read(length) }
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
              keep_pos(stream, pos: obj.dataplus) { |s| s.write(obj.data + "\x00") }
              write_size_t(stream, obj.capacity)
            else
              stream.write(obj.data + "\x00")
            end
            stream.pos = pos + LOCAL_CAPACITY + 1
          end
        end
      end
    end
  end
end
