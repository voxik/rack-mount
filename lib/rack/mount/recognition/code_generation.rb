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

                m << matchers = MetaMethod::Condition.new do |body|
                  body << path_name_condition = MetaMethod::Condition.new do |b|
                    b << "env[Const::PATH_INFO] = Utils.normalize_path(env[Const::PATH_INFO].sub(path_name_match, Const::EMPTY_STRING))"
                    b << "env[Const::PATH_INFO] = Const::EMPTY_STRING if env[Const::PATH_INFO] == Const::SLASH"
                    b << "env[Const::SCRIPT_NAME] = Utils.normalize_path(env[Const::SCRIPT_NAME].to_s + path_name_match)"
                  end
                  path_name_condition << MetaMethod::Block.new("path_name_match")
                  body << "env[#{@parameters_key.inspect}] = routing_args"
                  body << "response = route.app.call(env)"
                  body << "env[Const::PATH_INFO] = old_path_info"
                  body << "env[Const::SCRIPT_NAME] = old_script_name"
                  body << "return response unless response[0] == #{@catch}"
                end

                route.conditions.each do |method, condition|
                  matchers << MetaMethod::Block.new do |b|
                    b << "value = req.#{method}"
                    b << "if m = value.match(#{condition.inspect})"
                    b << "  matches = m.captures"
                    b << "  #{condition.named_captures.inspect}.each { |k, i|"
                    b << "    if v = matches[i]"
                    b << "      routing_args[k] = v"
                    b << "    end"
                    b << "  }"
                    if condition.is_a?(PathCondition) && !condition.anchored?
                      b << "  path_name_match = m.to_s"
                    end
                    b << "  true"
                    b << "else"
                    b << "  false"
                    b << "end"
                  end
                end
              }

              m << 'nil'
              # puts "\n#{m.inspect}"
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
