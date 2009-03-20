require 'strscan'

module Rack
  module Mount
    class RegexpWithNamedGroups < Regexp
      def self.extract_comment_capture_names(regexp)
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

        return names
      end

      def initialize(regexp, names = nil)
        case names
        when Hash
          @names = []
          names.each { |k, v| @names[v.to_int-1] = k.to_s }
        when Array
          @names = names.map { |n| n && n.to_s }
        else
          @names = self.class.extract_comment_capture_names(regexp)
          regexp = regexp.source.gsub(/\(\?#:[a-z]+\)/, '')
        end

        unless @names.any?
          @names = nil
        end

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
    end
  end
end
