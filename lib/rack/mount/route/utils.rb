module Rack
  module Mount
    class Route
      module Utils
        def extract_static_segments(regexp)
          if regexp.to_s =~ %r{\(\?-mix:?(.+)?\)}
            m = $1
            m.gsub!(/^(\^)|(\$)$/, "")
            segments = m.split("\\/").map { |segment|
              if segment =~ /^(\w+)$/
                $1
              else
                nil
              end
            }
            segments.shift
            while segments.any? && segments.last.nil?
              segments.pop
            end
            segments
          else
            []
          end
        end
        module_function :extract_static_segments
      end
    end
  end
end
