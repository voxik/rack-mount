module Rack
  module Mount
    module Generation
      module Condition
        # Segment data structure used for generations
        # => ['/people', ['.', :format]]
        def segments
          @segments ||= parse_segments(Utils.extract_regexp_parts(to_regexp))
        rescue ArgumentError
          @segments = Const::EMPTY_ARRAY
        end

        def freeze
          segments
          super
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
                  s << Route::DynamicSegment.new(part.name, requirement)
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
      end
    end
  end
end
