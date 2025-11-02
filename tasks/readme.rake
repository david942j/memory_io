# frozen_string_literal: true

desc 'To auto generate README.md from README.tpl'
task :readme do
  next if ENV['CI']

  require 'memory_io'
  require 'stringio'

  @tpl = File.binread('README.tpl.md')

  # Generate implemented structures list
  module Impl
    module_function

    def type_map
      @type_map ||= MemoryIO::Types::Type.instance_variable_get(:@map)
    end

    def type_map_h
      type_map.to_h
    end

    # fetch all keys
    # @return [Array<Array<Symbol>>]
    def keys
      type_map_h.values.map(&:keys).uniq
    end

    # @return [Array<String>]
    def compl_keys
      ary = keys.map do |ks|
        ret = ks.select { |k| k.to_s.include?('/') }.max_by(&:size)
        # ret ||= "others/#{ks.max_by(&:size)}"
        ret.to_s.split('/')
      end.sort
      custom_sort(ary)
    end

    def custom_sort(ary)
      ary.sort do |x, y|
        next x <=> y if x.first != y.first || x.first != 'basic'

        order = %w[u s f d]
        a = order.index(x.last[0])
        b = order.index(y.last[0])
        next a <=> b if a != b

        x.last[1..].to_i <=> y.last[1..].to_i
      end
    end

    def gen
      raise if compl_keys.map(&:size).uniq != [2]

      out = StringIO.new
      last_scope = ''
      compl_keys.each do |skey|
        scope = skey.first
        out.puts("\n### #{scope.upcase}") if scope != last_scope
        key = skey.join('/').to_sym
        rec = type_map[key]
        docs = rec.doc.lines
        aliases = rec.keys.reject { |z| z == key }.map { |z| "`:#{z}`" }.join(', ')
        out.puts(format('- `%s`: %s Also known as: %s', key, docs.shift.strip, aliases))
        last_scope = scope
      end
      out.string
    end
  end
  @tpl.gsub!('IMPLEMENTED_STRUCTURES', Impl.gen)

  File.binwrite('README.md', @tpl)
end
