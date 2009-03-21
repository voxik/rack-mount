module Rack
  module Mount
    module Optimizations
      module RouteSet
        def add_route(*args)
          route = super
          route.extend Optimizations::Route
          route
        end

        def freeze
          optimize_call! unless frozen?
          super
        end

        private
          def optimize_call!
            instance_eval(<<-EOS, __FILE__, __LINE__)
              def call(env)
                req = Request.new(env)
                keys = [#{@keys.map { |key| "req.#{key}" }.join(", ")}]
                @recognition_graph[*keys].each do |route|
                  result = route.call(env)
                  return result unless result[0] == 404
                end
                nil
              end
            EOS
          end
      end
    end
  end
end
