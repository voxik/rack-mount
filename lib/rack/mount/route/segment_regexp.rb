module Rack
  module Mount
    class Route
      class SegmentRegexp < Regexp
        def initialize(regexp, requirements = {})
          @requirements = requirements || {}
          super(regexp)
        end

        def segments_keys
          []
        end

        def recognizer
          self
        end

        def params
          @params ||= begin
            @requirements.sort { |a, b|
              a = Integer(a[1].gsub(/(^\[|\]$)/, ""))
              b = Integer(b[1].gsub(/(^\[|\]$)/, ""))
              a <=> b
            }.transpose[0]
          end
        end

        def freeze
          params

          super
        end
      end
    end
  end
end
