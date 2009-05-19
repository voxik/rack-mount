module Rack
  module Mount
    module Recognition
      module CodeGeneration #:nodoc:
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
                <<-EOS
                  route = self[#{i}]
                  routing_args = route.defaults.dup
                  if #{conditional_statement(route)}
                    env[#{@parameters_key.inspect}] = routing_args
                    result = route.app.call(env)
                    return result unless result[0] == #{@catch}
                  end
                EOS
              }.join

              method = <<-EOS, __FILE__, __LINE__
                def optimized_each(req)
                  env = req.env
#{body}
                  nil
                end
              EOS

              puts method if ENV[Const::RACK_MOUNT_DEBUG]
              list.instance_eval(*method)
            end

            instance_eval(<<-EOS, __FILE__, __LINE__)
              def call(env)
                env[Const::PATH_INFO] = Utils.normalize_path(env[Const::PATH_INFO])
                cache = {}
                req = #{@request_class.name}.new(env)
                @recognition_graph[#{convert_keys_to_method_calls}].optimized_each(req) || @throw
              end
            EOS
          end

          def conditional_statement(route)
            route.conditions.values.map { |condition|
              "route.conditions[:#{condition.method}].match!(req.#{condition.method}, env, routing_args)"
            }.compact.join(' && ')
          end

          def convert_keys_to_method_calls
            recognition_keys.map { |key|
              if key.is_a?(Array)
                "PathCondition.split(cache, req, :#{key.first}, #{key.last})"
              else
                "req.#{key}"
              end
            }.join(', ')
          end
      end
    end
  end
end
