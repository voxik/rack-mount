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

          routing_args = @defaults.dup
          if @conditions.all? { |method, condition|
            condition.match!(req.send(method), routing_args)
          }
            env[@parameters_key] = routing_args
            @app.call(env)
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
