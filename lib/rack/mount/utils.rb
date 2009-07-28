require 'rack/mount/regexp_with_named_groups'
require 'strscan'

module Rack::Mount
  # Private utility methods used throughout Rack::Mount.
  module Utils
    # Normalizes URI path.
    #
    # Strips off trailing slash and ensures there is a leading slash.
    #
    #   normalize_path("/foo")  # => "/foo"
    #   normalize_path("/foo/") # => "/foo"
    #   normalize_path("foo")   # => "/foo"
    #   normalize_path("")      # => "/"
    def normalize_path(path)
      path = "/#{path}"
      path.squeeze!(Const::SLASH)
      path.sub!(%r{/+\Z}, Const::EMPTY_STRING)
      path = Const::SLASH if path == Const::EMPTY_STRING
      path
    end
    module_function :normalize_path

    # Removes trailing nils from array.
    #
    #   pop_trailing_nils!([1, 2, 3])           # => [1, 2, 3]
    #   pop_trailing_nils!([1, 2, 3, nil, nil]) # => [1, 2, 3]
    #   pop_trailing_nils!([nil])               # => []
    def pop_trailing_nils!(ary)
      while ary.length > 0 && ary.last.nil?
        ary.pop
      end
      ary
    end
    module_function :pop_trailing_nils!

    # Determines whether the regexp must match the entire string.
    #
    #   regexp_anchored?(/^foo$/) # => true
    #   regexp_anchored?(/foo/)   # => false
    #   regexp_anchored?(/^foo/)  # => false
    #   regexp_anchored?(/foo$/)  # => false
    def regexp_anchored?(regexp)
      regexp.source =~ /\A(\\A|\^).*(\\Z|\$)\Z/ ? true : false
    end
    module_function :regexp_anchored?

    # Returns static string source of Regexp if it only includes static
    # characters and no metacharacters. Otherwise the original Regexp is
    # returned.
    #
    #   extract_static_regexp(/^foo$/)      # => "foo"
    #   extract_static_regexp(/^foo\.bar$/) # => "foo.bar"
    #   extract_static_regexp(/^foo|bar$/)  # => /^foo|bar$/
    def extract_static_regexp(regexp)
      if regexp.is_a?(String)
        regexp = Regexp.compile("\\A#{regexp}\\Z")
      end

      source = regexp.source
      if regexp_anchored?(regexp)
        source.sub!(/^(\\A|\^)(.*)(\\Z|\$)$/, '\2')
        unescaped_source = source.gsub(/\\/, Const::EMPTY_STRING)
        if source == Regexp.escape(unescaped_source) &&
            Regexp.compile("\\A(#{source})\\Z") =~ unescaped_source
          return unescaped_source
        end
      end
      regexp
    end
    module_function :extract_static_regexp

    if Const::SUPPORTS_NAMED_CAPTURES
      NAMED_CAPTURE_REGEXP = /\?<([^>]+)>/.freeze
    else
      NAMED_CAPTURE_REGEXP = /\?:<([^>]+)>/.freeze
    end

    # Strips shim named capture syntax and returns a clean Regexp and
    # an ordered array of the named captures.
    #
    #   extract_named_captures(/[a-z]+/)          # => /[a-z]+/, []
    #   extract_named_captures(/(?:<foo>[a-z]+)/) # => /([a-z]+)/, ['foo']
    #   extract_named_captures(/([a-z]+)(?:<foo>[a-z]+)/)
    #     # => /([a-z]+)([a-z]+)/, [nil, 'foo']
    def extract_named_captures(regexp)
      options = regexp.is_a?(Regexp) ? regexp.options : nil
      source = Regexp.compile(regexp).source
      names, scanner = [], StringScanner.new(source)

      while scanner.skip_until(/\(/)
        if scanner.scan(NAMED_CAPTURE_REGEXP)
          names << scanner[1]
        else
          names << nil
        end
      end

      source.gsub!(NAMED_CAPTURE_REGEXP, Const::EMPTY_STRING)
      return Regexp.compile(source, options), names
    end
    module_function :extract_named_captures

    class Capture < Array #:nodoc:
      attr_reader :name, :optional
      alias_method :optional?, :optional

      def initialize(*args)
        options = args.last.is_a?(Hash) ? args.pop : {}

        @name = options.delete(:name)
        @name = @name.to_s if @name

        @optional = options.delete(:optional) || false

        super(args)
      end

      def ==(obj)
        obj.is_a?(Capture) && @name == obj.name && @optional == obj.optional && super
      end

      def optionalize!
        @optional = true
        self
      end

      def named?
        name && name != Const::EMPTY_STRING
      end

      def to_s
        source = "(#{join})"
        source << '?' if optional?
        source
      end

      def first_char
        char = first[0..0]
        char = first[1..1] if char == '\\'
        char.is_a?(self.class) ? char.first_char : char
      end

      def last_char
        char = last[-1..-1]
        char.is_a?(self.class) ? char.last_char : char
      end

      def freeze
        each { |e| e.freeze }
        super
      end
    end

    def extract_regexp_parts(regexp) #:nodoc:
      unless regexp.is_a?(RegexpWithNamedGroups)
        regexp = RegexpWithNamedGroups.new(regexp)
      end

      if regexp.source =~ /\?<([^>]+)>/
        regexp, names = extract_named_captures(regexp)
      else
        names = regexp.names
      end
      source = regexp.source

      source =~ /^(\\A|\^)/ ? source.gsub!(/^(\\A|\^)/, Const::EMPTY_STRING) :
        raise(ArgumentError, "#{source} needs to match the start of the string")

      scanner = StringScanner.new(source)
      stack = [[]]

      capture_index = 0
      until scanner.eos?
        char = scanner.getch
        cur  = stack.last

        escaped = cur.last.is_a?(String) && cur.last[-1, 1] == '\\'

        if char == '\\' && scanner.peek(1) == 'Z'
          scanner.pos += 1
          cur.push(Const::NULL)
        elsif escaped
          cur.push('') unless cur.last.is_a?(String)
          cur.last << char
        elsif char == '('
          name = names[capture_index]
          capture = Capture.new(:name => name)
          capture_index += 1
          cur.push(capture)
          stack.push(capture)
        elsif char == ')'
          capture = stack.pop
          if scanner.peek(1) == '?'
            scanner.pos += 1
            capture.optionalize!
          end
        elsif char == '$'
          cur.push(Const::NULL)
        else
          cur.push('') unless cur.last.is_a?(String)
          cur.last << char
        end
      end

      result = stack.pop
      result.each { |e| e.freeze }
      result
    end
    module_function :extract_regexp_parts

    def analyze_capture_boundaries(regexps) #:nodoc:
      boundaries = Hash.new(0)
      regexps.each do |regexp|
        last = peek = nil
        extract_regexp_parts(regexp).each do |part|
          break if part == Const::NULL

          if peek
            char = part.is_a?(Capture) ? part.first_char : part[0..0]
            boundaries[char] += 1
            peek = nil
          end

          if part.is_a?(Capture)
            peek = true
          end

          if part.is_a?(Capture) && part.optional?
            char = part.first_char
            boundaries[char] += 1
          end

          if last && part.is_a?(Capture)
            char = last.is_a?(Capture) ? last.last_char : last[-1..-1]
            boundaries[char] += 1
          end

          last = part
        end
      end
      boundaries
    end
    module_function :analyze_capture_boundaries
  end
end
