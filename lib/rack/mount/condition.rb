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
          @pattern = Regexp.compile("^#{@pattern}$")
        end

        @keys[method] = Utils.extract_static_regexp(@pattern)
        @pattern = RegexpWithNamedGroups.new(@pattern)
      end

      def anchored?
        Utils.regexp_anchored?(@pattern)
      end

      def inspect
        to_regexp.inspect
      end

      def freeze
        @pattern.freeze
        @keys.freeze

        super
      end
    end

    class PathCondition < Condition #:nodoc:
      SEPARATORS_REGEXP = Regexp.union('/', '.', '?').freeze

      def self.split(cache, request, method, index)
        ary = cache[method] ||= begin
          value = request.send(method)
          value = Utils.normalize_path(value)
          keys = value.split(SEPARATORS_REGEXP)
          keys.shift
          keys << Const::EOS_KEY
          keys
        end
        ary[index]
      end

      def initialize(method, pattern)
        @method = method

        @pattern = pattern
        if @pattern.is_a?(Regexp)
          @pattern = RegexpWithNamedGroups.new(@pattern)
        elsif @pattern.is_a?(String)
          @pattern = Utils.normalize_path(@pattern)
          @pattern = RegexpWithNamedGroups.compile("^#{@pattern}$")
        end

        @keys = {}
        generate_keys(@pattern, %w( / )).each_with_index do |value, index|
          @keys[[method, index]] = value
        end
      end

      private
        # Keys for inserting into grapp
        # #=> ['people', /[0-9]+/, 'edit']
        def generate_keys(regexp, separators)
          escaped_separators = separators.map { |s| Regexp.escape(s) }
          separators_regexp = Regexp.union(*escaped_separators)
          segments = []

          begin
            Utils.extract_regexp_parts(regexp).each do |part|
              raise ArgumentError if part.is_a?(Utils::Capture)

              part = part.dup
              part.gsub!(/^\//, '')

              scanner = StringScanner.new(part)

              until scanner.eos?
                if s = scanner.scan_until(separators_regexp)
                  # Pop off matched separator
                  s.gsub!(/.$/, '')
                else
                  s = scanner.rest
                  scanner.terminate
                end

                if s == '$'
                  segments << Const::EOS_KEY
                  break
                end

                raise ArgumentError if matches_separator?(s, separators)
                static = Utils.extract_static_regexp(s)
                segments << (static.is_a?(String) ? static : nil)
              end
            end
          rescue ArgumentError
            # generation failed somewhere, but lets take what we can get
          end

          Utils.pop_trailing_nils!(segments)

          segments.freeze
        end

        def matches_separator?(source, separators)
          separators.each do |separator|
            if Regexp.compile("^#{source}$") =~ separator
              return true
            end
          end
          false
        end
    end
  end
end
