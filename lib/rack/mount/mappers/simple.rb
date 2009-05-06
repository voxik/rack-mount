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
        REQUEST_METHODS = Mount::Route::VALID_CONDITIONS.map { |m| m.to_s }

        def initialize(set)
          @set = set
        end

        def map(*args)
          options = args.last.is_a?(Hash) ? args.pop : {}

          app = options[:to]
          path = args[0]
          if method = args[1]
            method = method.to_s.upcase unless method.is_a?(Regexp)
          end
          defaults = options[:with]
          name = options[:name]

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
          @set.add_route(app, conditions, defaults, name)
        end
      end
    end
  end
end
