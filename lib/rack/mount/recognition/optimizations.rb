module Rack
  module Mount
    module Recognition
      module Optimizations #:nodoc:
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
            recognition_graph.lists.each do |list|
              body = (0...list.length).zip(list).map { |i, route|
                assign_index_params = assign_index_params(route)
                <<-EOS
                  if #{route.conditions[:method] ? "method =~ #{route.conditions[:method].inspect} && " : ''}#{route.conditions[:path] ? "path =~ #{route.conditions[:path].inspect}" : ''}
                    route = self[#{i}]
                    #{if assign_index_params.any?
                      'routing_args, param_matches = route.defaults.dup, $~.captures'
                    else
                      'routing_args = route.defaults.dup'
                    end}
                    #{assign_index_params.join("\n                  ")}
                    env[#{@parameters_key.inspect}] = routing_args
                    result = route.app.call(env)
                    return result unless result[0] == #{@catch}
                  end
                EOS
              }.join

              method = <<-EOS, __FILE__, __LINE__
                def optimized_each(env)
                  method = env[Const::REQUEST_METHOD]
                  path = Utils.normalize(env[Const::PATH_INFO])
#{body}
                  nil
                end
              EOS

              puts method if ENV[Const::RACK_MOUNT_DEBUG]
              list.instance_eval(*method)
            end

            instance_eval(<<-EOS, __FILE__, __LINE__)
              def call(env)
                req = Request.new(env)
                keys = [#{convert_keys_to_method_calls}]
                @recognition_graph[*keys].optimized_each(env) || @throw
              end
            EOS
          end

          def convert_keys_to_method_calls
            recognition_keys.map { |key|
              "req.#{key}"
            }.join(', ')
          end

          def assign_index_params(route)
            if named_captures = route.instance_variable_get("@named_captures")
              named_captures.map { |k, index|
                "routing_args[#{k.inspect}] = param_matches[#{index}] if param_matches[#{index}]"
              }
            else
              []
            end
          end
      end
    end
  end
end
