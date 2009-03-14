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

      def []=(*args)
        args  = args.flatten
        value = args.pop.freeze
        key   = args.shift.freeze
        keys  = args.freeze

        raise ArgumentError, "missing value" unless value

        if key.nil?
          if keys.empty?
            self << value
          else
            self.default = NestedSet.new(default) if default.is_a?(List)

            values_with_default.each do |v|
              v[keys.dup] = value
            end
          end
        else
          v = at(key)
          v = v.dup if v.equal?(default)

          if keys.empty?
            v << value
          else
            v = NestedSet.new(v) if v.is_a?(List)
            v[keys.dup] = value
          end

          super(key, v)
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

      def depth
        values_with_default.map { |v|
          v.is_a?(NestedSet) ? v.depth : v.length
        }.max { |a, b| a <=> b }
      end

      def to_graph
        require 'rack/mount/graphviz_ext'

        g = GraphViz::new("G")
        g[:nodesep] = ".05"
        g[:rankdir] = "LR"

        g.node[:shape] = "record"
        g.node[:width] = ".1"
        g.node[:height] = ".1"

        g.add_object(self)

        g
      end
    end
  end
end
