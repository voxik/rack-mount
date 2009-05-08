module Rack
  module Mount
    class Condition #:nodoc:
      class << self
        alias_method :new2, :new
        def new(*args)
          if args.first == :path
            PathCondition.new2(*args)
          else
            Condition.new2(*args)
          end
        end
      end

      attr_reader :method, :pattern
      alias_method :to_regexp, :pattern

      attr_reader :keys

      def initialize(method, pattern)
        @method = method.to_sym

        @pattern = pattern
        if @pattern.is_a?(String)
          @keys = [pattern]
          @pattern = Regexp.compile("^#{@pattern}$")
        else
          @keys = [@pattern]
        end
      end

      def key
        @keys.first
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
      def initialize(method, pattern)
        @method = method
        raise ArgumentError unless @method == :path

        @pattern = pattern
        if @pattern.is_a?(Regexp)
          @pattern = RegexpWithNamedGroups.new(@pattern)
        elsif @pattern.is_a?(String)
          @pattern = Utils.normalize_path(@pattern)
          @pattern = RegexpWithNamedGroups.compile("^#{@pattern}$")
        end

        @keys = generate_keys(@pattern, %w( / ))
      end

      private
        # Keys for inserting into NestedSet
        # #=> ['people', /[0-9]+/, 'edit']
        def generate_keys(regexp, separators)
          escaped_separators = separators.map { |s| Regexp.escape(s) }
          separators_regexp = Regexp.compile(escaped_separators.join('|'))
          segments = []

          begin
            Utils.extract_regexp_parts(regexp).each do |part|
              raise ArgumentError if part.is_a?(Utils::Capture)

              part = part.dup
              part.gsub!(/\\\//, '/')
              part.gsub!(/^\//, '')

              scanner = StringScanner.new(part)

              until scanner.eos?
                unless s = scanner.scan_until(separators_regexp)
                  s = scanner.rest
                  scanner.terminate
                end

                s.gsub!(/\/$/, '')
                raise ArgumentError if matches_separator?(s, separators)
                segments << (clean_regexp?(s) ? s : nil)
              end
            end

            segments << Const::EOS_KEY
          rescue ArgumentError
            # generation failed somewhere, but lets take what we can get
          end

          Utils.pop_trailing_nils!(segments)

          segments.freeze
        end

        def clean_regexp?(source)
          source =~ /^\w+$/
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
