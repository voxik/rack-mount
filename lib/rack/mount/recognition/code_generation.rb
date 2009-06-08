module Rack
  module Mount
    module Recognition
      module CodeGeneration #:nodoc:
        def freeze
          optimize_call! unless frozen?
          super
        end

        private
          def optimize_call!
            recognition_graph.containers_with_default.each do |list|
              m = MetaMethod.new(:optimized_each, :req)
              m << 'env = req.env'

              list.each_with_index { |route, i|
                m << "route = self[#{i}]"
                m << 'old_path_info = env[Const::PATH_INFO].dup'
                m << 'old_script_name = env[Const::SCRIPT_NAME].dup'
                m << 'path_name_match = nil'
                m << 'routing_args = route.defaults.dup'
                m << <<-RUBY_EVAL
if route.conditions.all? { |method, condition|
    value = req.send(method)
    if m = value.match(condition.to_regexp)
      matches = m.captures
      condition.named_captures.each { |k, i|
        if v = matches[i]
          routing_args[k] = v
        end
      }
      if condition.is_a?(PathCondition) && !condition.anchored?
        path_name_match = m.to_s
      end
      true
    else
      false
    end
  }
    if path_name_match
      env[Const::PATH_INFO] = Utils.normalize_path(env[Const::PATH_INFO].sub(path_name_match, Const::EMPTY_STRING))
      env[Const::PATH_INFO] = Const::EMPTY_STRING if env[Const::PATH_INFO] == Const::SLASH
      env[Const::SCRIPT_NAME] = Utils.normalize_path(env[Const::SCRIPT_NAME].to_s + path_name_match)
    end
    env[#{@parameters_key.inspect}] = routing_args
    response = route.app.call(env)
    env[Const::PATH_INFO] = old_path_info
    env[Const::SCRIPT_NAME] = old_script_name
    return response unless response[0] == #{@catch}
  end
RUBY_EVAL
              }

              m << 'nil'
              list.instance_eval(m, __FILE__, __LINE__)
            end

            method = MetaMethod.new(:call, :env)
            method << 'env[Const::PATH_INFO] = Utils.normalize_path(env[Const::PATH_INFO])'
            method << 'cache = {}'
            method << "req = #{@request_class.name}.new(env)"
            method << "@recognition_graph[#{convert_keys_to_method_calls}].optimized_each(req) || @throw"
            instance_eval(method, __FILE__, __LINE__)
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
