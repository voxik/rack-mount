require 'strscan'

module Rack
  module Mount
    module Utils
      SEPARATORS = %w( / . ? )
      GLOB_REGEXP = /\/\\\*(\w+)$/
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

        # Hack in temporary support for one level of optional segments
        if re =~ /\\\((.+)\\\)/
          re.sub!(/\\\((.+)\\\)/, "\(\\1\)?")
        end

        RegexpWithNamedGroups.new("^#{re}$")
      end
      module_function :convert_segment_string_to_regexp

      # Old parser that extracted named captures from comments
      def extract_comment_capture_names(regexp)
        names, scanner, last_close = [], StringScanner.new(regexp.source), nil

        while scanner.skip_until(/\(/)
          next if scanner.pre_match =~ /\\$/

          if scanner.scan(/\?\#(.+?)(?=\))/)
            if scanner[1] =~ /^:(\w+)$/
              names[last_close] = $1.to_s
            end
          else
            names << :capture
          end

          while scanner.skip_until(/[()]/)
            if scanner.matched =~ /\)$/
              (names.size - 1).downto(0) do |i|
                if names[i] == :capture
                  names[last_close = i] = nil
                  break
                end
              end
            else
              scanner.unscan
              break
            end
          end
        end

        regexp = regexp.source.gsub(/\(\?#:[a-z]+\)/, '')
        return Regexp.compile(regexp), names
      end
      module_function :extract_comment_capture_names

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
    end
  end
end
