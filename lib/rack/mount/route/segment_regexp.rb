module Rack
  module Mount
    class Route
      class SegmentRegexp < Regexp
        def initialize(regexp, requirements = nil)
          super(regexp)

          if requirements.is_a?(Hash)
            @names = requirements.sort { |a, b|
              a[1].to_int <=> b[1].to_int
            }.transpose[0].map { |n| n.to_s }
          elsif requirements.is_a?(Array)
            @names = requirements.map { |n| n.to_s }
          end
        end

        def segment_keys
          if to_s =~ %r{\(\?-mix:(.*)\)}
            $1.split("\\/").map { |segment|
              if segment =~ /^(\w+)$/
                $1
              else
                nil
              end
            }
          else
            []
          end
        end

        def to_regexp
          self
        end

        def names
          @names || super
        rescue NoMethodError
          []
        end
      end
    end
  end
end
