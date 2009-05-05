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
        REQUEST_METHODS = %w( method path scheme )

        def initialize(set)
          @set = set
        end

        def map(*args)
          options = args.last.is_a?(Hash) ? args.pop : {}

          app = options[:to]
          path = args[0]
          method = args[1]
          defaults = options[:with]

          conditions, requirements = {}, {}

          (options[:conditions] || {}).each do |k,v|
            v = v.to_s unless v.is_a?(Regexp)
            REQUEST_METHODS.include?(k.to_s) ?
              conditions[k] = v :
              requirements[k] = v
          end

          if path.is_a?(String)
            path = Utils.convert_segment_string_to_regexp(path, requirements, %w( / . ? ))
          end

          conditions.merge!(:method => method, :path => path)
          @set.add_route(app, conditions, defaults)
        end
      end
    end
  end
end
