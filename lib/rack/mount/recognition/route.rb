module Rack
  module Mount
    module Recognition
      module Route #:nodoc:
        attr_reader :keys
        attr_writer :throw, :parameters_key

        def initialize(*args)
          super

          @throw          = Const::NOT_FOUND_RESPONSE
          @parameters_key = Const::RACK_ROUTING_ARGS
          @keys           = generate_keys
        end

        def call(req)
          env = req.env
          old_path_info = env[Const::PATH_INFO].dup
          old_script_name = env[Const::SCRIPT_NAME].dup
          path_name_match = nil

          routing_args = @defaults.dup
          if @conditions.all? { |method, condition|
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
            env[@parameters_key] = routing_args
            response = @app.call(env)
            env[Const::PATH_INFO] = old_path_info
            env[Const::SCRIPT_NAME] = old_script_name
            response
          else
            @throw
          end
        end

        private
          def generate_keys
            @set.valid_conditions.inject({}) do |keys, method|
              if @conditions.has_key?(method)
                keys.merge!(@conditions[method].keys)
              end
              keys
            end
          end
      end
    end
  end
end
