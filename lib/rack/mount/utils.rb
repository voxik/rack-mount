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
        separators = Regexp.compile(separators.map { |s| Regexp.escape(s) }.join('|'))
        segments = []

        begin
          extract_regexp_parts(regexp).each do |part|
            break if part.is_a?(Capture)

            part = part.dup
            part.gsub!(/\\\//, '/')
            part.gsub!(/^\//, '')

            scanner = StringScanner.new(part)

            until scanner.eos?
              unless s = scanner.scan_until(separators)
                s = scanner.rest
                scanner.terminate
              end

              s.gsub!(/\/$/, '')
              segments << (s =~ /^\w+$/ ? s : nil)
            end
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

      class Capture < Array
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
          each do |e|
            e.gsub!(/\?<([^>]+)>/, '') if e.is_a?(String)
            e.freeze
          end

          super
        end
      end

      def extract_regexp_parts(regexp)
        unless regexp.is_a?(RegexpWithNamedGroups)
          regexp = RegexpWithNamedGroups.new(regexp)
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

          if char == '('
            name = regexp.names[capture_index]
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
    end
  end
end
