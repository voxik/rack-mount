require 'strscan'

module Rack
  module Mount
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
        path.sub!(%r'/+$', Const::EMPTY_STRING)
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

      GLOB_REGEXP = /\/\\\*(\w+)/
      OPTIONAL_SEGMENT_REGEXP = /\\\((.+?)\\\)/
      SEGMENT_REGEXP = /(:([a-z](_?[a-z0-9])*))/

      def convert_segment_string_to_regexp(str, requirements = {}, separators = [])
        raise ArgumentError unless str.is_a?(String)

        str = Regexp.escape(str.dup)
        requirements = requirements || {}
        str = normalize_path(str)

        re = ''

        while m = (str.match(SEGMENT_REGEXP))
          re << m.pre_match unless m.pre_match.empty?
          if requirement = requirements[$2.to_sym]
            re << Const::REGEXP_NAMED_CAPTURE % [$2, requirement.source]
          else
            re << Const::REGEXP_NAMED_CAPTURE % [$2, "[^#{separators.join}]+"]
          end
          str = m.post_match
        end

        re << str unless str.empty?

        if m = re.match(GLOB_REGEXP)
          re.sub!(GLOB_REGEXP, "/#{Const::REGEXP_NAMED_CAPTURE % [$1, '.*']}")
        end

        while re =~ OPTIONAL_SEGMENT_REGEXP
          re.gsub!(OPTIONAL_SEGMENT_REGEXP, '(\1)?')
        end

        RegexpWithNamedGroups.new("^#{re}$")
      end
      module_function :convert_segment_string_to_regexp

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
          @name == obj.name && @optional == obj.optional && super
        end

        def optionalize!
          @optional = true
          self
        end

        def named?
          name && name != ''
        end

        def freeze
          each { |e| e.freeze }
          super
        end
      end

      METACHARACTERS = %w( . [ ] ^ $ * + )

      def extract_regexp_parts(regexp)
        unless regexp.is_a?(RegexpWithNamedGroups)
          regexp = RegexpWithNamedGroups.new(regexp)
        end

        if regexp.source =~ /\?<([^>]+)>/
          regexp, names = extract_named_captures(regexp)
        else
          names = regexp.names
        end
        source = regexp.source

        source =~ /^\^/ ? source.gsub!(/^\^/, '') :
          raise(ArgumentError, "#{source} needs to match the start of the string")
        source.gsub!(/\$$/, '')

        scanner = StringScanner.new(source)
        stack = [[]]

        capture_index = 0
        until scanner.eos?
          char = scanner.getch
          cur  = stack.last

          escaped = cur.last.is_a?(String) && cur.last == '\\'

          if char == '('
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
          # elsif !escaped && METACHARACTERS.include?(char)
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

      if Const::SUPPORTS_NAMED_CAPTURES
        NAMED_CAPTURE_REGEXP = /\?<([^>]+)>/.freeze
      else
        NAMED_CAPTURE_REGEXP = /\?:<([^>]+)>/.freeze
      end

      def extract_named_captures(regexp)
        source = Regexp.compile(regexp).source
        names, scanner = [], StringScanner.new(source)

        while scanner.skip_until(/\(/)
          if scanner.scan(NAMED_CAPTURE_REGEXP)
            names << scanner[1]
          else
            names << nil
          end
        end

        source.gsub!(NAMED_CAPTURE_REGEXP, '')
        return Regexp.compile(source), names
      end
      module_function :extract_named_captures

      def analysis_keys(possible_key_set)
        keys = {}
        possible_key_set.each do |possible_keys|
          possible_keys.each do |key, value|
            keys[key] ||= 0
            keys[key] += 1
          end
        end
        keys = keys.sort { |e1, e2| e1[1] <=> e2[1] }
        keys.reverse!
        keys.map! { |e| e[0] }
        keys
      end
      module_function :analysis_keys
    end
  end
end
