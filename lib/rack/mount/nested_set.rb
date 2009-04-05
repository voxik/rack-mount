module Rack
  module Mount
    class NestedSet < Hash
      class List < Array
        undef :[], :[]=

        def freeze
          each { |e| e.freeze }
          super
        end
      end

      def initialize(default = List.new)
        super(default)
      end

      alias_method :at, :[]

      WILD_REGEXP = /.*/.freeze

      def []=(*args)
        args  = args.flatten
        value = args.pop
        key   = args.shift.freeze
        key   = WILD_REGEXP if key.nil?
        keys  = args.freeze

        raise ArgumentError, "missing value" unless value

        case key
        when Regexp
          if keys.empty?
            each { |k, v| v << value if key =~ k }
            default << value
          else
            each { |k, v| v[keys.dup] = value if key =~ k }
            self.default = NestedSet.new(default) if default.is_a?(List)
            default[keys.dup] = value
          end
        when String
          v = at(key)
          v = v.dup if v.equal?(default)

          if keys.empty?
            v << value
          else
            v = NestedSet.new(v) if v.is_a?(List)
            v[keys.dup] = value
          end

          super(key, v)
        else
          raise ArgumentError, "unsupported key"
        end
      end

      def [](*keys)
        result, i = self, 0
        until result.is_a?(Array)
          result = result.at(keys[i])
          i += 1
        end
        result
      end

      def <<(value)
        values_with_default.each { |e| e << value }
        nil
      end

      def values_with_default
        values.push(default)
      end

      def inspect
        super.gsub(/\}$/, ", nil => #{default.inspect}}")
      end

      def freeze
        values_with_default.each { |v| v.freeze }
        super
      end

      def height
        longest_list_descendant.length
      end

      protected
        def list_descendants
          descendants = []
          values_with_default.each do |v|
            if v.is_a?(NestedSet)
              v.list_descendants.each do |descendant|
                descendants << descendant
              end
            else
              descendants << v
            end
          end
          descendants
        end

      private
        def longest_list_descendant
          list_descendants.max { |a, b| a.length <=> b.length }
        end
    end
  end
end
