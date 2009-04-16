module Rack
  module Mount
    class RouteSet
      module Optimizations
        def add_route(*args)
          route = super
          route.extend Route::Optimizations
          route
        end

        def freeze
          optimize_call! unless frozen?
          super
        end

        if ENV[Const::RACK_MOUNT_DEBUG]
          def instance_eval(*args)
            puts
            puts "#{args[1]}##{args[2]}"
            puts args[0]
            puts

            super
          end
        end

        private
          def optimize_call!
            instance_eval(<<-EOS, __FILE__, __LINE__)
              def call(env)
                req = Request.new(env)
                keys = [#{convert_keys_to_method_calls}]
                @recognition_graph[*keys].each do |route|
                  result = route.call(env)
                  return result unless result[0] == @catch
                end
                @throw
              end
            EOS
          end

          def convert_keys_to_method_calls
            @recognition_keys.map { |key|
              if key.is_a?(Array)
                key = key.dup
                "req.#{key.shift}(#{key.join(',')})"
              else
                "req.#{key}"
              end
            }.join(', ')
          end
      end
    end
  end
end
