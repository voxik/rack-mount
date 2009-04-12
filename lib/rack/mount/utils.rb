require 'strscan'

module Rack
  module Mount
    module Utils
      SEPARATORS = %w( / . ? )
      GLOB_REGEXP = /\/\\\*(\w+)$/
      OPTIONAL_SEGMENT_REGEXP = /\\\((.+)\\\)/
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
            re << Const::REGEXP_NAMED_CAPTURE % [$2, requirement.source]
          else
            re << Const::REGEXP_NAMED_CAPTURE % [$2, "[^#{SEPARATORS.join}]+"]
          end
          str = m.post_match
        end

        re << str unless str.empty?

        if m = re.match(GLOB_REGEXP)
          re.sub!(GLOB_REGEXP, "/#{Const::REGEXP_NAMED_CAPTURE % [$1, ".*"]}")
        end

        while re =~ OPTIONAL_SEGMENT_REGEXP
          re.gsub!(OPTIONAL_SEGMENT_REGEXP, '(\1)?')
        end

        RegexpWithNamedGroups.new("^#{re}$")
      end
      module_function :convert_segment_string_to_regexp

      def extract_static_segments(regexp, separators)
        segments = []

        begin
          generate_regexp_parts(regexp, separators) do |part|
            segments << part
          end
        rescue ArgumentError
          # generation failed somewhere, but lets take what we can get
        end

        # Pop off trailing nils
        while segments.length > 0 && segments.last.nil?
          segments.pop
        end

        segments
      end
      module_function :extract_static_segments

      def generate_regexp_parts(regexp, separators)
        separators = separators.map { |s| Regexp.escape(s) }
        separators = Regexp.compile(separators.join('|'))

        source = regexp.source

        source =~ /^\^/ ? source.gsub!(/^\^/, '') :
          raise(ArgumentError, "#{source} needs to match the start of the string")

        source.gsub!(/\$$/, '')
        source.gsub!(%r{\\/}, '/')
        source.gsub!(/^\//, '')

        scanner = StringScanner.new(source)

        until scanner.eos?
          unless s = scanner.scan_until(separators)
            s = scanner.rest
            scanner.terminate
          end

          s.gsub!(/\/$/, '')

          if s =~ /^\w+$/
            yield s
          else
            yield nil
          end
        end
      end
      module_function :generate_regexp_parts
    end
  end
end
