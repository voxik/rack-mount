require 'rack/mount/meta_method'

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
                m << 'routing_args = route.defaults.dup'

                m << matchers = MetaMethod::Condition.new do |body|
                  body << "env[#{@parameters_key.inspect}] = routing_args"
                  body << "response = route.app.call(env)"
                  body << "return response unless response[0].to_i == 417"
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
                      if condition.method == :path_info && !condition.anchored?
                        b << "env[Prefix::KEY] = m.to_s"
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

            if @routes.empty?
              method << 'env[Const::EXPECT] != Const::CONTINUE ? Const::NOT_FOUND_RESPONSE : Const::EXPECTATION_FAILED_RESPONSE'
            else
              method << 'begin'
              method << 'set_expectation = env[Const::EXPECT] != Const::CONTINUE'
              method << 'env[Const::EXPECT] = Const::CONTINUE if set_expectation'

              method << 'env[Const::PATH_INFO] = Utils.normalize_path(env[Const::PATH_INFO])'
              method << "req = #{@request_class.name}.new(env)"
              cache = false
              keys = recognition_keys.map { |key|
                if key.is_a?(Array)
                  cache = true
                  "(cache[:#{key.first}] ||= SplitCondition.apply(req.#{key.first}, %r{/}))[#{key.last}]"
                else
                  "req.#{key}"
                end
              }.join(', ')
              method << 'cache = {}' if cache
              method << "@recognition_graph[#{keys}].optimized_each(req) || (set_expectation ? Const::NOT_FOUND_RESPONSE : Const::EXPECTATION_FAILED_RESPONSE)"
              method << 'ensure'
              method << 'env.delete(Const::EXPECT) if set_expectation'
              method << 'end'
            end

            # puts "\n#{method.inspect}"
            instance_eval(method)
          end
      end
    end
  end
end
