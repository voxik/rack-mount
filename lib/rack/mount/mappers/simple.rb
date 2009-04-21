module Rack
  module Mount
    class RouteSet
      def prepare
        map = Mappers::Simple.new(self)
        yield map
        freeze
      end
    end

    module Mappers
      class Simple
        def initialize(set)
          @set = set
        end

        def map(*args)
          options = args.last.is_a?(Hash) ? args.pop : {}

          app = options[:to]
          path = args[0]
          method = args[1]
          defaults = options[:with]

          requirements = options[:conditions] || {}
          requirements.each { |k,v| requirements[k] = v.to_s unless v.is_a?(Regexp) }

          conditions = { :method => method, :path => path }
          @set.add_route(app, conditions, requirements, defaults)
        end
      end
    end
  end
end
