module Rack
  module Mount
    class Route
      module Utils
        SEPARATORS   = %w( / . ? )
        PARAM_REGEXP = /^:(\w+)$/
        GLOB_REGEXP  = /^\\\*(\w+)$/
        SEGMENT_REGEXP = /[^\/\.\?]+|[\/\.\?]/

        def convert_segment_string_to_regexp(str, requirements = {})
          raise ArgumentError unless str.is_a?(String)

          str = str.dup
          requirements = requirements || {}
          str.replace("/#{str}") unless str =~ /^\//
          names = []

          re = str.scan(SEGMENT_REGEXP).map { |segment|
            next if segment == ""
            segment = Regexp.escape(segment)

            if segment =~ PARAM_REGEXP
              names << $1
              "(#{requirements[$1.to_sym] || "[^#{SEPARATORS.join}]+"})"
            elsif segment =~ GLOB_REGEXP
              names << $1
              "(.*)"
            else
              segment
            end
          }.compact.join

          RegexpWithNamedGroups.new("^#{re}$", names)
        end
        module_function :convert_segment_string_to_regexp

        def extract_static_segments(regexp)
          if regexp.to_s =~ %r{\(\?-mix:?(.+)?\)}
            m = $1
            m.gsub!(/^(\^)|(\$)$/, "")
            segments = m.split(%r{\\/|\\\.|\\\?}).map { |segment|
              if segment =~ /^(\w+)$/
                $1
              else
                nil
              end
            }

            segments.shift
            while segments.length > 0 && segments.last.nil?
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
