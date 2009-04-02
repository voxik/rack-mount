module Rack
  module Mount
    class Route
      module Recognition
        def call(env)
          method = env[Const::REQUEST_METHOD]
          path = env[Const::PATH_INFO]

          if (@method.nil? || method == @method) && path =~ @recognizer
            routing_args, param_matches = @defaults.dup, $~.captures
            @indexed_params.each { |k, i|
              if v = param_matches[i]
                routing_args[k] = v
              end
            }
            env[Const::RACK_ROUTING_ARGS] = routing_args
            @app.call(env)
          else
            @throw
          end
        end
      end
    end
  end
end
