module Rack
  module Mount
    class RouteSet
      DEFAULT_OPTIONS = {
        :keys => [:method, :first_segment]
      }.freeze

      def initialize(options = {}, &block)
        @options = DEFAULT_OPTIONS.dup.merge!(options)
        @keys = @options.delete(:keys)
        @named_routes = {}
        @root = NestedSet.new

        if block_given?
          block.call(self)
          freeze
        end
      end

      def add_route(app, options = {})
        route = Route.new(app, options)
        keys = @keys.map { |key| route.send(key) }
        @root[*keys] = route
        @named_routes[route.name] = route if route.name
        route
      end

      def url_for(named_route, options = {})
        @named_routes[named_route.to_sym].url_for(options)
      end

      def call(env)
        raise "route set not finalized" unless frozen?

        env_str = Request.new(env)
        keys = @keys.map { |key| env_str.send(key) }
        @root[*keys].each do |route|
          result = route.call(env)
          return result unless result[0] == 404
        end
        nil
      end

      def freeze
        @root.freeze
        super
      end

      def worst_case
        @root.depth
      end

      def to_graph
        @root.to_graph
      end
    end
  end
end
