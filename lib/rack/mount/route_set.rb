module Rack
  module Mount
    class RouteSet
      DEFAULT_OPTIONS = {
        :optimize => false,
        :keys => [:method, :first_segment]
      }.freeze

      def initialize(options = {})
        @options = DEFAULT_OPTIONS.dup.merge!(options)
        @keys = @options.delete(:keys)

        @named_routes = {}
        @recognition_graph = NestedSet.new
        @generation_graph = NestedSet.new

        if @options[:optimize]
          extend Optimizations::RouteSet
        end

        if block_given?
          yield self
          freeze
        end
      end

      def add_route(app, options = {})
        route = Route.new(app, options)

        if @options[:optimize]
          route.extend Optimizations::Route
        end

        @named_routes[route.name] = route if route.name

        keys = @keys.map { |key| route.send(key) }
        @recognition_graph[*keys] = route

        controller = route.defaults[:controller]
        action     = route.defaults[:action]
        @generation_graph[controller, action] = route

        route
      end

      def url_for(*args)
        params = args.pop if args.last.is_a?(Hash)
        named_route = args.shift

        if named_route
          route = @named_routes[named_route.to_sym]
        else
          controller = params[:controller]
          action     = params[:action]
          route = @generation_graph[controller, action].first
        end

        route.url_for(params)
      end

      def call(env)
        raise "route set not finalized" unless frozen?

        req = Request.new(env)
        keys = @keys.map { |key| req.send(key) }
        @recognition_graph[*keys].each do |route|
          result = route.call(env)
          return result unless result[0] == 404
        end
        nil
      end

      def freeze
        @named_routes.freeze
        @recognition_graph.freeze
        @generation_graph.freeze

        super
      end

      def deepest_node
        @recognition_graph.deepest_node
      end

      def height
        @recognition_graph.height
      end

      def to_graph
        @recognition_graph.to_graph
      end
    end
  end
end
