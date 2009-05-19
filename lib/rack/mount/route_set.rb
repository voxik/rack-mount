module Rack
  module Mount
    class RouteSet
      extend Mixover

      # Include generation and recognition concerns
      include Generation::RouteSet, Recognition::RouteSet
      include Recognition::CodeGeneration

      # Initialize a new RouteSet without optimizations
      def self.new_without_optimizations(*args, &block)
        @included_modules ||= []
        @included_modules.delete(Recognition::CodeGeneration)
        new(*args, &block)
      ensure
        @included_modules.push(Recognition::CodeGeneration)
      end

      # Basic RouteSet initializer.
      #
      # If a block is given, the set is yielded and finalized.
      #
      # See other aspects for other valid options:
      # - <tt>Generation::RouteSet.new</tt>
      # - <tt>Recognition::RouteSet.new</tt>
      def initialize(options = {}, &block)
        @request_class = options.delete(:request_class) || Rack::Request

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
        route = Route.new(self, app, conditions, defaults, name)
        @routes << route
        route
      end

      # See <tt>Recognition::RouteSet#call</tt>
      def call(env)
        raise NotImplementedError
      end

      # See <tt>Generation::RouteSet#url_for</tt>
      def url_for(*args)
        raise NotImplementedError
      end

      # Number of routes in the set
      def length
        @routes.length
      end

      # Finalizes the set and builds optimized data structures. You *must*
      # freeze the set before you can use <tt>call</tt> and <tt>url_for</tt>.
      # So remember to call freeze after you are done adding routes.
      def freeze
        @routes.freeze
        super
      end

      private
        # An internal helper method for constructing a nested set from
        # the linear route set.
        #
        # build_nested_route_set([:request_method, :path_info]) { |route, method|
        #   route.send(method)
        # }
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
