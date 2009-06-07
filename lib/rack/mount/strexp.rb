module Rack
  module Mount
    class Strexp < Regexp
      GLOB_REGEXP = /\\\*(\w+)/
      OPTIONAL_SEGMENT_REGEXP = /\\\((.+?)\\\)/

      # Parses segmented string expression and converts it into a Regexp
      #
      #   Strexp.compile('foo')
      #     # => %r{^foo$}
      #
      #   Strexp.compile('foo/:bar', {}, ['/'])
      #     # => %r{^foo/(?<bar>[^/]+)$}
      #
      #   Strexp.compile(':foo.example.com')
      #     # => %r{^(?<foo>.+)\.example\.com$}
      #
      #   Strexp.compile('foo/:bar', {:bar => /[a-z]+/}, ['/'])
      #     # => %r{^foo/(?<bar>[a-z]+)$}
      #
      #   Strexp.compile('foo(.:extension)')
      #     # => %r{^foo(\.(?<extension>.+))?$}
      #
      #   Strexp.compile('src/*files')
      #     # => %r{^src/(?<files>.+)$}
      def initialize(str, requirements = {}, separators = [])
        return super(str) if str.is_a?(Regexp)

        str = Regexp.escape(str.dup)
        requirements = normalize_requirements!(requirements, separators)

        re = parse_dynamic_segments(str, requirements)

        if m = re.match(GLOB_REGEXP)
          re.sub!(GLOB_REGEXP, Const::REGEXP_NAMED_CAPTURE % [$1, '.+'])
        end

        while re =~ OPTIONAL_SEGMENT_REGEXP
          re.gsub!(OPTIONAL_SEGMENT_REGEXP, '(\1)?')
        end

        super("^#{re}$")
      end

      private
        def normalize_requirements!(requirements, separators)
          requirements ||= {}
          requirements.each do |key, value|
            requirements[key] = value.is_a?(Regexp) ?
              value.source : Regexp.escape(value)
          end
          requirements.default ||= separators.any? ?
            "[^#{separators.join}]+" : '.+'
          requirements
        end

        def parse_dynamic_segments(str, requirements)
          re, pos, scanner = '', 0, StringScanner.new(str)
          while scanner.scan_until(/:([a-zA-Z_]\w*)/)
            pre, pos = scanner.pre_match[pos..-1], scanner.pos
            if pre =~ /(.*)\\\\$/
              re << $1 + scanner.matched
            else
              name = scanner[1].to_sym
              re << pre + Const::REGEXP_NAMED_CAPTURE % [name, requirements[name]]
            end
          end
          re << scanner.rest
          re
        end
    end
  end
end
