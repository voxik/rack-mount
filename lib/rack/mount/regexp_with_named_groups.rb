module Rack
  module Mount
    class RegexpWithNamedGroups < Regexp
      def initialize(regexp, names = nil)
        names = nil if names && !names.any?

        case names
        when Hash
          @names = []
          names.each { |k, v| @names[v.to_int-1] = k.to_s }
        when Array
          @names = names.map { |n| n && n.to_s }
        else
          regexp, @names = extract_shim_named_captures(regexp)
        end

        @names = nil unless @names.any?

        if @names
          @named_captures = {}
          @names.each_with_index { |n, i| @named_captures[n] = [i+1] if n }
        end

        super(regexp)
      end

      if instance_methods.include?(:named_captures)
        def named_captures
          @named_captures ||= super
        end
      else
        def named_captures
          @named_captures ||= {}
        end
      end

      if instance_methods.include?(:names)
        def names
          @names ||= super
        end
      else
        def names
          @names ||= []
        end
      end

      def freeze
        named_captures
        names
        super
      end

      private
        SHIM_NAMED_CAPTURE = /\?:<([^>]+)>/.freeze

        def extract_shim_named_captures(regexp)
          require 'strscan'
          source = Regexp.compile(regexp).source
          names, scanner = [], StringScanner.new(source)

          while scanner.skip_until(/\(/)
            if scanner.scan(SHIM_NAMED_CAPTURE)
              names << scanner[1]
            else
              names << nil
            end
          end

          regexp = source.gsub(SHIM_NAMED_CAPTURE, '')
          return Regexp.compile(regexp), names
        end
    end
  end
end
