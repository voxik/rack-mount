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
                path_info_unanchored = route.conditions[:path_info] &&
                  !route.conditions[:path_info].anchored?
                m << "route = self[#{i}]"
                m << 'old_path_info = env[Const::PATH_INFO].dup'
                m << 'old_script_name = env[Const::SCRIPT_NAME].dup'
                m << 'path_name_match = nil' if path_info_unanchored
                m << 'routing_args = route.defaults.dup'

                m << matchers = MetaMethod::Condition.new do |body|
                  if path_info_unanchored
                    body << MetaMethod::Condition.new("path_name_match") do |c|
                      c << "env[Const::PATH_INFO] = Utils.normalize_path(env[Const::PATH_INFO].sub(path_name_match, Const::EMPTY_STRING))"
                      c << "env[Const::PATH_INFO] = Const::EMPTY_STRING if env[Const::PATH_INFO] == Const::SLASH"
                      c << "env[Const::SCRIPT_NAME] = Utils.normalize_path(env[Const::SCRIPT_NAME].to_s + path_name_match)"
                    end
                  end
                  body << "env[#{@parameters_key.inspect}] = routing_args"
                  body << "response = route.app.call(env)"
                  if path_info_unanchored
                    body << "env[Const::PATH_INFO] = old_path_info"
                    body << "env[Const::SCRIPT_NAME] = old_script_name"
                  end
                  body << "return response unless response[0] == #{@catch}"
                end

                route.conditions.each do |method, condition|
                  matchers << MetaMethod::Block.new do |matcher|
                    matcher << c = MetaMethod::Condition.new("m = req.#{method}.match(#{condition.inspect})") do |b|
                      b << "matches = m.captures" if condition.named_captures.any?
                      condition.named_captures.each do |k, i|
                        b << MetaMethod::Condition.new("p = matches[#{i}]") do |c2|
                          c2 << "routing_args[#{k.inspect}] = p"
                        end
                      end
                      if condition.is_a?(PathCondition) && !condition.anchored?
                        b << "path_name_match = m.to_s"
                      end
                      b << "true"
                    end
                    c.else = MetaMethod::Block.new("false")
                  end
                end
              }

              m << 'nil'
              # puts "\n#{m.inspect}"
              list.instance_eval(m)
            end

            method = MetaMethod.new(:call, :env)
            method << 'env[Const::PATH_INFO] = Utils.normalize_path(env[Const::PATH_INFO])'
            method << 'cache = {}'
            method << "req = #{@request_class.name}.new(env)"
            method << "@recognition_graph[#{convert_keys_to_method_calls}].optimized_each(req) || @throw"
            instance_eval(method)
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
