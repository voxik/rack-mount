require 'strscan'

module Rack
  module Mount
    module Utils
      SEPARATORS = %w( / . ? )
      GLOB_REGEXP = /\/\\\*(\w+)$/
      OPTIONAL_SEGMENT_REGEXP = /\\\((.+)\\\)/
      SEGMENT_REGEXP = /(:([a-z](_?[a-z0-9])*))/

      if RUBY_VERSION >= '1.9'
        NAMED_CAPTURE = "(?<%s>%s)"
      else
        NAMED_CAPTURE = "(?:<%s>%s)"
      end

      def convert_segment_string_to_regexp(str, requirements = {})
        raise ArgumentError unless str.is_a?(String)

        str = Regexp.escape(str.dup)
        requirements = requirements || {}
        str.replace("/#{str}") unless str =~ /^\//

        re = ""

        while m = (str.match(SEGMENT_REGEXP))
          re << m.pre_match unless m.pre_match.empty?
          if requirement = requirements[$2.to_sym]
            re << NAMED_CAPTURE % [$2, requirement.source]
          else
            re << NAMED_CAPTURE % [$2, "[^#{SEPARATORS.join}]+"]
          end
          str = m.post_match
        end

        re << str unless str.empty?

        if m = re.match(GLOB_REGEXP)
          re.sub!(GLOB_REGEXP, "/#{NAMED_CAPTURE % [$1, ".*"]}")
        end

        while re =~ OPTIONAL_SEGMENT_REGEXP
          re.gsub!(OPTIONAL_SEGMENT_REGEXP, '(\1)?')
        end

        RegexpWithNamedGroups.new("^#{re}$")
      end
      module_function :convert_segment_string_to_regexp

      def extract_named_captures(regexp)
        names, scanner = [], StringScanner.new(regexp.source)

        while scanner.skip_until(/\(/)
          next if scanner.pre_match =~ /\\$/

          if scanner.scan(/\?:<([^>]+)>/)
            names << scanner[1]
          else
            names << nil
          end
        end

        regexp = regexp.source.gsub(/\?:<[^>]+>/, '')
        return Regexp.compile(regexp), names
      end
      module_function :extract_named_captures

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

      def parse_segments_with_optionals(pattern, nest_level = 0)
        segments = []

        while segment = pattern.slice!(/^(?:|.*?[^\\])(?:\\\\)*([\(\)])/)
          segments.concat parse_segments(segment[0..-2]) if segment.length > 1
          if segment[-1, 1] == '('
            segments << parse_segments_with_optionals(pattern, nest_level + 1)
          else
            raise ArgumentError, "There are too many closing parentheses" if nest_level == 0
            return segments
          end
        end

        segments.concat parse_segments(pattern) unless pattern.empty?

        raise ArgumentError, "You have too many opening parentheses" unless nest_level == 0

        segments
      end
      module_function :parse_segments_with_optionals

      def parse_segments(path)
        segments = []

        while match = (path.match(/(?:(:|\*)([a-z](?:_?[a-z0-9])*))/i))
          segment_name = match[2].to_sym

          # Handle false-positives due to escaped special characters
          if match.pre_match =~ /(?:^|[^\\])\\(?:\\\\)*$/
            segments << "#{match.pre_match[0..-2]}#{match[0]}"
          else
            segments << match.pre_match unless match.pre_match.empty?
            segments << segment_name
          end

          path = match.post_match
        end

        segments << path unless path.empty?
        segments
      end
      module_function :parse_segments
    end
  end
end
