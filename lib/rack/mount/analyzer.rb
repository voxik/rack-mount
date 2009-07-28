module Rack::Mount
  class Analyzer #:nodoc:
    def self.split(value, separator_pattern)
      keys = value.split(separator_pattern)
      keys.shift if keys[0] == Const::EMPTY_STRING
      keys << Const::NULL
      keys
    end

    def initialize(*keys)
      clear
      keys.each { |key| self << key }
    end

    def clear
      @raw_keys = []
      @boundaries = Histogram.new
      @key_frequency = Histogram.new
      self
    end

    def <<(key)
      raise ArgumentError unless key.is_a?(Hash)
      @raw_keys << key
      key.each_pair { |_, value| analyze_capture_boundaries(value, @boundaries) }
      nil
    end

    def separators
      @separators ||= @boundaries.select_upper
    end

    def separator_pattern
      @separator_pattern ||= Regexp.union(*separators).freeze
    end

    def possible_keys
      @possible_keys ||= begin
        @raw_keys.map do |key|
          key.inject({}) { |requirements, (method, requirement)|
            raise ArgumentError unless method.is_a?(Symbol)

            if requirement.is_a?(Regexp) && method == :path_info
              generate_split_keys(requirement, separators).each_with_index do |value, index|
                requirements[[method, index, separator_pattern]] = value
              end
            elsif requirement.is_a?(Regexp)
              requirements[method] = Utils.extract_static_regexp(requirement)
            else
              requirements[method] = requirement
            end

            requirements
          }
        end
      end
    end

    def report
      @report ||= begin
        possible_keys.each { |keys| keys.each_pair { |key, _| @key_frequency << key } }
        return [] if @key_frequency.count <= 1
        @key_frequency.select_upper
      end
    end

    private
      class Histogram < Hash #:nodoc:
        attr_reader :count

        def initialize
          @count = 0
          super(0)
        end

        def <<(value)
          @count += 1
          self[value] += 1 if value
        end

        def select_upper
          values = sort_by { |_, value| value }
          values.reverse!
          values = values.select { |_, value| value >= count / size }
          values.map! { |key, _| key }
          values
        end
      end

      def analyze_capture_boundaries(regexp, boundaries) #:nodoc:
        return boundaries unless regexp.is_a?(Regexp)

        parts = extract_regexp_parts(regexp) rescue []
        parts.each_with_index do |part, index|
          break if part == Const::NULL

          if index > 0
            previous = parts[index-1]
            previous = Utils.extract_static_regexp(previous.last_part) if previous.is_a?(Utils::Capture)
            boundaries << previous[-1..-1] if previous.is_a?(String)
          end

          if index < parts.length
            following = parts[index+1]
            following = Utils.extract_static_regexp(following.first_part) if following.is_a?(Utils::Capture)
            if following.is_a?(String) && following != Const::NULL
              boundaries << following[0..0] == '\\' ? following[1..1] : following[0..0]
            end
          end
        end
        boundaries
      end

      def generate_split_keys(regexp, separators) #:nodoc:
        escaped_separators = separators.map { |s| Regexp.escape(s) }
        separators_regexp = Regexp.union(*escaped_separators)
        segments, previous = [], nil

        begin
          extract_regexp_parts(regexp).each do |part|
            if part.respond_to?(:optional?) && part.optional?
              if escaped_separators.include?(part.first)
                append_to_segments!(segments, previous, separators)
              end

              raise ArgumentError
            end

            append_to_segments!(segments, previous, separators)
            previous = nil

            if part == Const::NULL
              segments << Const::NULL
              raise ArgumentError
            end

            if part.is_a?(Utils::Capture)
              source = part.map { |p| p.to_s }.join
              append_to_segments!(segments, source, separators)
            else
              scanner = StringScanner.new(part)
              while s = scanner.scan_until(separators_regexp)
                s = s[0...-scanner.matched_size]
                append_to_segments!(segments, s, separators)
              end
              previous = scanner.rest
            end
          end

          append_to_segments!(segments, previous, separators)
        rescue ArgumentError
          # generation failed somewhere, but lets take what we can get
        end

        Utils.pop_trailing_nils!(segments)

        segments.freeze
      end

      def append_to_segments!(segments, s, separators) #:nodoc:
        if s && s != Const::EMPTY_STRING
          separators.each do |separator|
            if Regexp.compile("\\A#{s}\\Z") =~ separator
              raise ArgumentError
            end
          end

          static = Utils.extract_static_regexp(s)
          segments << (static.is_a?(String) ? static : static)
        end
      end

      def extract_regexp_parts(regexp) #:nodoc:
        (@parts ||= {})[regexp] ||= Utils.extract_regexp_parts(regexp)
      end
  end
end
