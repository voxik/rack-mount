module Rack::Mount
  module Analysis
    module Splitting
      NULL = "\0".freeze

      class Key < Array
        def initialize(method, index, separators)
          replace([method, index, separators])
        end

        def self.split(value, separator_pattern)
          keys = value.split(separator_pattern)
          keys.shift if keys[0] == ''
          keys << NULL
          keys
        end

        def call(cache, obj)
          (cache[self[0]] ||= self.class.split(obj.send(self[0]), self[2]))[self[1]]
        end

        def call_source(cache, obj)
          "(#{cache}[:#{self[0]}] ||= Analysis::Splitting::Key.split(#{obj}.#{self[0]}, #{self[2].inspect}))[#{self[1]}]"
        end
      end

      def clear
        @boundaries = {}
        super
      end

      def <<(key)
        super
        key.each_pair do |k, v|
          analyze_capture_boundaries(v, @boundaries[k] ||= Histogram.new)
        end
      end

      def separators(key)
        @boundaries[key].select_upper
      end

      def process_key(requirements, method, requirement)
        separators = separators(method)
        if requirement.is_a?(Regexp) && separators.any?
          generate_split_keys(requirement, separators).each_with_index do |value, index|
            requirements[Key.new(method, index, Regexp.union(*separators))] = value
          end
        else
          super
        end
      end

      private
        def analyze_capture_boundaries(regexp, boundaries) #:nodoc:
          return boundaries unless regexp.is_a?(Regexp)

          parts = Utils.parse_regexp(regexp)
          parts.each_with_index do |part, index|
            if part.is_a?(RegexpParser::Group)
              if index > 0
                previous = parts[index-1]
                if previous.is_a?(RegexpParser::Character)
                  boundaries << previous.value.to_str
                end
              end

              if inside = part[0][0]
                if inside.is_a?(RegexpParser::Character)
                  boundaries << inside.value.to_str
                end
              end

              if index < parts.length
                following = parts[index+1]
                if following.is_a?(RegexpParser::Character)
                  boundaries << following.value.to_str
                end
              end
            end
          end

          boundaries
        end

        def generate_split_keys(regexp, separators) #:nodoc:
          segments = []
          buf = nil
          casefold = regexp.casefold?
          parts = Utils.parse_regexp(regexp)
          parts.each_with_index do |part, index|
            if part.is_a?(RegexpParser::Anchor)
              if part.value == '^' || part.value == '\A'
              elsif part.value == '$' || part.value == '\Z'
                segments << join_buffer(buf, regexp) if buf
                segments << NULL
                buf = nil
                break
              end
            elsif part.is_a?(RegexpParser::Character)
              value = part.value
              if separators.include?(value)
                segments << join_buffer(buf, regexp) if buf
                peek = parts[index+1]
                if peek.is_a?(RegexpParser::Character) && separators.include?(peek.value)
                  segments << ''
                end
                buf = nil
              else
                buf ||= []
                buf << part
              end
            elsif part.is_a?(RegexpParser::Group)
              if part.quantifier == '?'
                value = part.value.first.value
                if separators.include?(value)
                  segments << join_buffer(buf, regexp) if buf
                  buf = nil
                end
                break
              elsif part.quantifier == nil
                break if part.value.any? { |p|
                  separators.any? { |s| p.include?(s) }
                }
                buf = nil
                segments << Regexp.compile("\\A#{part.to_regexp}\\Z")
              else
                break
              end
            elsif part.is_a?(RegexpParser::CharacterRange)
              break if separators.any? { |s| part.include?(s) }
              buf = nil
              segments << Regexp.compile("\\A#{part.regexp_source}\\Z")
            else
              break
            end

            if index + 1 == parts.size
              segments << join_buffer(buf, regexp) if buf
              buf = nil
              break
            end
          end

          while segments.length > 0 && (segments.last.nil? || segments.last == '')
            segments.pop
          end

          segments.shift if segments[0].nil? || segments[0] == ''

          segments
        end

        def join_buffer(parts, regexp)
          if parts.all? { |p| p.quantifier.nil? } && !regexp.casefold?
            parts.map { |p| p.value }.join
          else
            source = parts.map { |p| p.regexp_source }.join
            Regexp.compile("\\A#{source}\\Z", regexp.options)
          end
        end
    end
  end
end
