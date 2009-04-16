module Rack
  module Mount
    class Route
      module Optimizations
        def freeze
          optimize_call! unless frozen?
          super
        end

        if ENV[Const::RACK_MOUNT_DEBUG]
          def instance_eval(*args)
            puts
            puts inspect
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
                method = env[Const::REQUEST_METHOD]
                path = env[Const::PATH_INFO]

                if #{@method ? 'method == @method && ' : ''}path =~ @recognizer
                  routing_args, param_matches = @defaults.dup, $~.captures
                  #{assign_index_params}
                  env[Const::RACK_ROUTING_ARGS] = routing_args
                  @app.call(env)
                else
                  @throw
                end
              end
            EOS
          end

          def assign_index_params
            @named_captures.map { |k, i|
              "routing_args[#{k.inspect}] = param_matches[#{i}] if param_matches[#{i}]"
            }.join("\n                  ")
          end
      end
    end
  end
end
