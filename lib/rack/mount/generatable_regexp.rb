require 'rack/mount/utils'

module Rack::Mount
  class GeneratableRegexp < Regexp #:nodoc:
    class DynamicSegment #:nodoc:
      attr_reader :name, :requirement

      def initialize(name, requirement)
        @name, @requirement = name.to_sym, bound_expression(requirement)
        freeze
      end

      def ==(obj)
        @name == obj.name && @requirement == obj.requirement
      end

      def =~(str)
        @requirement =~ str
      end

      def to_hash
        { @name => @requirement }
      end

      def inspect
        "/(?<#{@name}>#{@requirement.source})/"
      end

      private
        def bound_expression(regexp)
          source, options = regexp.source, regexp.options
          source = "\\A#{source}\\Z"
          Regexp.compile(source, options).freeze
        end
    end

    module InstanceMethods
      def self.extended(obj)
        obj.segments
      end

      def generatable?
        segments.any?
      end

      def generate(params = {}, recall = {}, defaults = {})
        merged = recall.merge(params)
        generate_from_segments(segments, params, merged, defaults)
      end

      def segments
        @segments ||= begin
          segments = Const::EMPTY_ARRAY
          catch(:halt) do
            segments = parse_segments(RegexpParser.new.parse_regexp(self))
          end
          segments
        end
      end

      def captures
        segments.flatten.find_all { |s| s.is_a?(DynamicSegment) }
      end

      def required_captures
        segments.find_all { |s| s.is_a?(DynamicSegment) }
      end

      private
        def parse_segments(segments)
          s = []
          segments.each_with_index do |part, index|
            case part
            when RegexpParser::Anchor
              # ignore
            when RegexpParser::Character
              if s.last.is_a?(String)
                s.last << part.value
              else
                s << part.value
              end
            when RegexpParser::Group
              if part.name
                requirement = Regexp.compile(part.to_regexp)
                s << DynamicSegment.new(part.name, requirement)
              else
                s << parse_segments(part)
              end
            when RegexpParser::Expression
              return parse_segments(part)
            else
              throw :halt
            end
          end

          s
        end

        def generate_from_segments(segments, params, merged, defaults, optional = false)
          if optional
            return Const::EMPTY_STRING if segments.all? { |s| s.is_a?(String) }
            return Const::EMPTY_STRING unless segments.flatten.any? { |s|
              params[s.name] if s.is_a?(DynamicSegment)
            }
            return Const::EMPTY_STRING if segments.any? { |segment|
              if segment.is_a?(DynamicSegment)
                value = merged[segment.name] || defaults[segment.name]
                value = value.to_param if value.respond_to?(:to_param)

                merged_value = merged[segment.name]
                merged_value = merged_value.to_param if merged_value.respond_to?(:to_param)

                default_value = defaults[segment.name]
                default_value = default_value.to_param if default_value.respond_to?(:to_param)

                if value.nil? || segment !~ value
                  true
                elsif merged_value == default_value
                  # Nasty control flow
                  return :clear_remaining_segments
                  true
                else
                  false
                end
              end
            }
          end

          generated = segments.map do |segment|
            case segment
            when String
              segment
            when DynamicSegment
              value = params[segment.name] || merged[segment.name] || defaults[segment.name]
              value = value.to_param if value.respond_to?(:to_param)
              if value && segment =~ value.to_s
                value
              else
                return
              end
            when Array
              value = generate_from_segments(segment, params, merged, defaults, true)
              if value == :clear_remaining_segments
                segment.each { |s| params.delete(s.name) if s.is_a?(DynamicSegment) }
                Const::EMPTY_STRING
              elsif value.nil?
                Const::EMPTY_STRING
              else
                value
              end
            end
          end

          # Delete any used items from the params
          segments.each { |s| params.delete(s.name) if s.is_a?(DynamicSegment) }

          generated.join
        end
    end
    include InstanceMethods

    def initialize(regexp)
      super
      segments
    end
  end
end
