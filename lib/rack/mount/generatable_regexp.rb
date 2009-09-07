require 'rack/mount/utils'
require 'uri'

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
          parse_segments(Utils.extract_regexp_parts(self))
        rescue ArgumentError
          Const::EMPTY_ARRAY
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
          segments.each do |part|
            if part.is_a?(String) && part == Const::NULL
              return s
            elsif part.is_a?(Utils::Capture)
              if part.named?
                source = part.map { |p| p.to_s }.join
                requirement = Regexp.compile(source)
                s << DynamicSegment.new(part.name, requirement)
              else
                s << parse_segments(part)
              end
            else
              part = part.gsub('\\/', '/')
              static = Utils.extract_static_regexp(part)
              if static.is_a?(String)
                s << static.freeze
              else
                raise ArgumentError, "failed to parse #{part.inspect}"
              end
            end
          end

          s.freeze
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
                value.nil? || segment !~ value.to_s || merged[segment.name] == defaults[segment.name]
              end
            }
          end

          generated = segments.map do |segment|
            case segment
            when String
              segment
            when DynamicSegment
              value = params[segment.name] || merged[segment.name] || defaults[segment.name]
              if value && segment =~ value.to_s
                URI.escape(value.to_s)
              else
                return
              end
            when Array
              generate_from_segments(segment, params, merged, defaults, true) || Const::EMPTY_STRING
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
