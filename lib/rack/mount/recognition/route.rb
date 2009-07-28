require 'rack/mount/prefix'

module Rack::Mount
  module Recognition
    module Route #:nodoc:
      def initialize(*args)
        super

        # TODO: Don't explict check for :path_info condition
        if @conditions.has_key?(:path_info) &&
            !@conditions[:path_info].anchored?
          @app = Prefix.new(@app)
        end
      end

      def call(req)
        env = req.env

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
            # TODO: Don't explict check for :path_info condition
            if condition.method == :path_info && !condition.anchored?
              env[Prefix::KEY] = m.to_s
            end
            true
          else
            false
          end
        }
          env[@set.parameters_key] = routing_args
          @app.call(env)
        else
          Const::EXPECTATION_FAILED_RESPONSE
        end
      end
    end
  end
end
