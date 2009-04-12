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

      def extract_static_segments(regexp, separators)
        separators = separators.map { |s| Regexp.escape(s) }
        separators = Regexp.compile(separators.join('|'))

        source = regexp.source
        source.gsub!(/^\^|\$$/, '')
        source.gsub!(%r{\\/}, '/')

        segments = []
        while m = source.match(separators)
          unless (s = m.pre_match) == ''
            if !s.empty? && s =~ /^\w+$/
              segments << s
            else
              segments << nil
            end
          end

          source = m.post_match
        end

        if !source.empty? && source =~ /^\w+$/
          segments << source
        else
          segments << nil
        end

        while segments.length > 0 && segments.last.nil?
          segments.pop
        end

        segments
      end
      module_function :extract_static_segments
    end
  end
end
