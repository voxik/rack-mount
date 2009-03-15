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

        def to_regexp
          self
        end

        def names
          @names ||= begin
            names = super if super.any? rescue NoMethodError

            names ||= @requirements.sort { |a, b|
              a = Integer(a[1].gsub(/(^\[|\]$)/, ""))
              b = Integer(b[1].gsub(/(^\[|\]$)/, ""))
              a <=> b
            }.transpose[0]

            (names || {}).map { |n| n.to_sym }
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
