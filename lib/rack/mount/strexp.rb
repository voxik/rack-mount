module Rack
  module Mount
    class Strexp < Regexp
      GLOB_REGEXP = /\\\*(\w+)/
      OPTIONAL_SEGMENT_REGEXP = /\\\((.+?)\\\)/
      SEGMENT_REGEXP = /(:([a-z](_?[a-z0-9])*))/

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
        raise ArgumentError unless str.is_a?(String)

        str = Regexp.escape(str.dup)
        requirements = requirements || {}
        default_requirement = separators.any? ?
          "[^#{separators.join}]+" : '.+'

        re = ''

        while m = (str.match(SEGMENT_REGEXP))
          re << m.pre_match unless m.pre_match.empty?
          if requirement = requirements[$2.to_sym]
            source = requirement.is_a?(String) ?
              Regexp.escape(requirement) :
              requirement.source
            re << Const::REGEXP_NAMED_CAPTURE % [$2, source]
          else
            re << Const::REGEXP_NAMED_CAPTURE % [$2, default_requirement]
          end
          str = m.post_match
        end

        re << str unless str.empty?

        if m = re.match(GLOB_REGEXP)
          re.sub!(GLOB_REGEXP, Const::REGEXP_NAMED_CAPTURE % [$1, '.+'])
        end

        while re =~ OPTIONAL_SEGMENT_REGEXP
          re.gsub!(OPTIONAL_SEGMENT_REGEXP, '(\1)?')
        end

        super("^#{re}$")
      end
    end
  end
end
