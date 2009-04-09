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
          regexp = Regexp.compile(regexp)
          regexp, @names = Utils.extract_named_captures(regexp)
        end

        @names = nil unless @names.any?

        if @names
          @named_captures = {}
          @names.each_with_index { |n, i| @named_captures[n] = [i+1] if n }
        end

        super(regexp)
      end

      def to_regexp
        self
      end

      if RUBY_VERSION >= '1.9'
        def named_captures
          @named_captures ||= super
        end
      else
        def named_captures
          @named_captures ||= {}
        end
      end

      if RUBY_VERSION >= '1.9'
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
    end
  end
end
