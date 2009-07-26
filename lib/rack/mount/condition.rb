require 'rack/mount/regexp_with_named_groups'
require 'rack/mount/utils'
require 'strscan'

module Rack
  module Mount
    class Condition #:nodoc:
      include Recognition::Condition

      attr_reader :method, :pattern
      alias_method :to_regexp, :pattern

      attr_reader :keys

      def initialize(method, pattern)
        @method = method.to_sym

        @pattern = pattern
        @keys = {}

        if @pattern.is_a?(String)
          @pattern = Regexp.escape(@pattern)
          @pattern = Regexp.compile("\\A#{@pattern}\\Z")
        end

        @keys[method] = Utils.extract_static_regexp(@pattern).freeze
        @pattern = RegexpWithNamedGroups.new(@pattern).freeze
      end

      def anchored?
        Utils.regexp_anchored?(@pattern)
      end

      def inspect
        to_regexp.inspect
      end
    end

    class SplitCondition < Condition #:nodoc:
      def self.apply(value, separator_pattern)
        keys = value.split(separator_pattern)
        keys.shift if keys[0] == Const::EMPTY_STRING
        keys << Const::NULL
        keys
      end

      def initialize(method, pattern, separators)
        super(method, pattern)

        @separators = separators.freeze
        @separator_pattern = Regexp.union(*@separators).freeze

        @keys = {}
        generate_keys(@pattern).each_with_index do |value, index|
          @keys[[method, index]] = value
        end
        @keys.freeze
      end

      def split(value)
        self.class.apply(value, @separator_pattern)
      end

      private
        def generate_keys(regexp)
          escaped_separators = @separators.map { |s| Regexp.escape(s) }
          separators_regexp = Regexp.union(*escaped_separators)
          segments, previous = [], nil

          begin
            Utils.extract_regexp_parts(regexp).each do |part|
              if part.respond_to?(:optional?) && part.optional?
                if escaped_separators.include?(part.first)
                  append_to_segments!(segments, previous)
                end

                raise ArgumentError
              end

              append_to_segments!(segments, previous)
              previous = nil

              if part == Const::NULL
                segments << Const::NULL
                raise ArgumentError
              end

              if part.is_a?(Utils::Capture)
                source = part.map { |p| p.to_s }.join
                append_to_segments!(segments, source)
              else
                scanner = StringScanner.new(part)
                while s = scanner.scan_until(separators_regexp)
                  s = s[0...-scanner.matched_size]
                  append_to_segments!(segments, s)
                end
                previous = scanner.rest
              end
            end

            append_to_segments!(segments, previous)
          rescue ArgumentError
            # generation failed somewhere, but lets take what we can get
          end

          Utils.pop_trailing_nils!(segments)

          segments.freeze
        end

        def append_to_segments!(segments, s)
          if s && s != Const::EMPTY_STRING
            @separators.each do |separator|
              if Regexp.compile("\\A#{s}\\Z") =~ separator
                raise ArgumentError
              end
            end

            static = Utils.extract_static_regexp(s)
            segments << (static.is_a?(String) ? static : static)
          end
        end
    end
  end
end
