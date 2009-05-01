module Rack
  module Mount
    class RouteSet < BaseClass
      include Generation::RouteSet, Recognition::RouteSet

      def initialize(options = {}, &block)
        if options.delete(:optimize) == true
          extend Recognition::Optimizations
        end

        @routes = []

        if block_given?
          yield self
          freeze
        end
      end

      # Builder method to add a route to the set
      #
      # <tt>app</tt>:: A valid Rack app to call if the conditions are met.
      # <tt>conditions</tt>:: A hash of conditions to match against.
      #                       Conditions may be expressed as strings or
      #                       regexps to match against.
      # <tt>defaults</tt>:: A hash of values that always gets merged in
      # <tt>name</tt>:: Symbol identifier for the route used with named 
      #                 route generations
      def add_route(app, conditions = {}, defaults = {}, name = nil)
        route = Route.new(app, conditions, defaults, name)
        @routes << route
        route
      end

      # See Rack::Mount::Recognition::RouteSet#call
      def call(env)
        raise NotImplementedError
      end

      # See Rack::Mount::Generation::RouteSet#url_for
      def url_for(*args)
        raise NotImplementedError
      end

      # Finalizes the set and builds optimized data structures. You *must*
      # freeze the set before you can use <tt>call</tt> and <tt>url_for</tt>. So remember
      # to call freeze after you are done adding routes.
      def freeze
        @routes.freeze
        super
      end

      private
        def build_nested_route_set(keys, &block)
          graph = NestedSet.new
          @routes.each do |route|
            k = keys.map { |key| block.call(route, key) }
            Utils.pop_trailing_nils!(k)
            graph[*k] = route
          end
          graph
        end
    end
  end
end
