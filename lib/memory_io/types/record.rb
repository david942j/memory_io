# frozen_string_literal: true

module MemoryIO
  module Types
    # @api private
    #
    # Class that handles a registered object in {Types::Type.find}.
    # For example, this class will parse inline-docs to generate README.md.
    class Record
      # @return [Object]
      #   Whatever.
      attr_reader :obj

      # @return [Array<Symbol>]
      #   All symbols that can find this record in {Type.find}.
      attr_reader :keys

      # Instantiate a {Record} object.
      #
      # @param [Object] object
      # @param [Array<Symbol>] keys
      #
      # @option [Thread::Backtrace::Location] caller
      #   This option should present if and only if +object+ is a subclass of {Types::Type}.
      # @option [String] doc
      #   Docstring.
      #   Automatically parse from caller location if this parameter isn't present.
      def initialize(object, keys, option = {})
        @obj = object
        @keys = keys
        @force_doc = option[:doc]
        @caller = option[:caller]
      end

      # Get the doc string.
      #
      # @return [String]
      #   If option +doc+ had been passed in {#initialize}, this method simply returns it.
      #   Otherwise, parse the file for inline-docs.
      #   If neither +doc+ nor +caller+ had been passed to {#initialize}, an empty string is returned.
      def doc
        return @force_doc if @force_doc
        return '' unless @caller

        parse_file_doc(@caller.absolute_path, @caller.lineno)
      end

      private

      # @return [String]
      def parse_file_doc(file, lineno)
        return '' unless ::File.file?(file)

        strings = []
        lines = ::IO.binread(file).split("\n")
        (lineno - 1).downto(1) do |no|
          str = lines[no - 1]
          break if str.nil?

          str.strip!
          break unless str.start_with?('#')

          strings.unshift(str[2..-1] || '')
        end
        trim_docstring(strings)
      end

      def trim_docstring(strings)
        strings = strings.drop_while { |s| s.start_with?('@') }.take_while { |s| !s.start_with?('@') }
        strings.drop_while(&:empty?).reverse.drop_while(&:empty?).reverse.join("\n") + "\n"
      end
    end
  end
end
