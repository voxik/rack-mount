module Rack
  module Mount
    class RouteSet
      module Base
        def initialize(options = {})
          if options.delete(:optimize) == true
            extend Optimizations
          end

          if block_given?
            yield self
            freeze
          end
        end

        def add_route(app, options = {})
          Route.new(app, options)
        end
      end
    end
  end
end
