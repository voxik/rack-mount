module Rack
  module Mount
    module Utils
      SEPARATORS = %w( / . ? )
      ESCAPED_SEPARATORS = SEPARATORS.map { |s| Regexp.escape(s) }

      PARAM_REGEXP = /^:(\w+)$/
      GLOB_REGEXP = /\/\\\*(\w+)$/
      OPTIONAL_SEGMENT_REGEX = /^.*(\(.+\))$/
      SEGMENT_REGEXP = /(:([a-z](_?[a-z0-9])*))/

      def convert_segment_string_to_regexp(str, requirements = {})
        raise ArgumentError unless str.is_a?(String)

        str = Regexp.escape(str.dup)
        requirements = requirements || {}
        str.replace("/#{str}") unless str =~ /^\//

        re = ""

        while m = (str.match(SEGMENT_REGEXP))
          re << m.pre_match unless m.pre_match.empty?
          if requirement = requirements[$2.to_sym]
            re << "(#{requirement.source})"
          else
            re << "([^#{SEPARATORS.join}]+)"
          end
          re << "(?#:#{$2})"
          str = m.post_match
        end

        re << str unless str.empty?

        if m = re.match(GLOB_REGEXP)
          re.sub!(GLOB_REGEXP, "/(.*)(?#:#{$1})")
        end

        # Hack in temporary support for optional segments
        if re =~ /\\\((.+)\\\)/
          re.sub!(/\\\((.+)\\\)/, "\(\\1\)?")
        end

        RegexpWithNamedGroups.new("^#{re}$")
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
