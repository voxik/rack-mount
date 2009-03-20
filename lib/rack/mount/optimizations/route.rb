module Rack
  module Mount
    module Optimizations
      module Route
        def freeze
          optimize_call! unless frozen?

          super
        end

        private
          def optimize_call!
            instance_eval(<<-EOS, __FILE__, __LINE__)
              def call(env)
                method = env["REQUEST_METHOD"]
                path = env["PATH_INFO"]

                if #{@method ? "method == @method && " : ""}path =~ @recognizer
                  routing_args, param_matches = {}, $~.captures
                  #{assign_index_params}
                  env["rack.routing_args"] = routing_args.merge!(@defaults)
                  @app.call(env)
                else
                  SKIP_RESPONSE
                end
              end
            EOS
          end

          def assign_index_params
            @indexed_params.map { |k, i|
              "routing_args[#{k.inspect}] = param_matches[#{i}] if param_matches[#{i}]"
            }.join("\n                  ")
          end
      end
    end
  end
end
