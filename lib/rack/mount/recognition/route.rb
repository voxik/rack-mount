require 'rack/mount/utils'

module Rack::Mount
  module Recognition
    module Route #:nodoc:
      attr_reader :named_captures

      def initialize(*args)
        super

        @named_captures = {}
        @conditions.map { |method, condition|
          @named_captures[method] = condition.named_captures.inject({}) { |named_captures, (k, v)|
            named_captures[k.to_sym] = v.last - 1
            named_captures
          }.freeze
        }
        @named_captures.freeze
      end

      def recognize(obj)
        params = @defaults.dup
        if @conditions.all? { |method, condition|
          value = obj.send(method)
          if m = value.match(condition)
            matches = m.captures
            @named_captures[method].each { |k, i|
              if v = matches[i]
                params[k] = v
              end
            }
            true
          else
            false
          end
        }
          params
        else
          nil
        end
      end

      def call(req)
        env = req.env

        routing_args = @defaults.dup
        if @conditions.all? { |method, condition|
          value = req.send(method)
          if m = value.match(condition)
            matches = m.captures
            @named_captures[method].each { |k, i|
              if v = matches[i]
                # TODO: We only want to unescape params from
                # uri related methods
                routing_args[k] = Utils.unescape_uri(v)
              end
            }
            true
          else
            false
          end
        }
          env[@set.parameters_key] = routing_args
          @app.call(env)
        else
          [417, {'Content-Type' => 'text/html'}, ['Expectation failed']]
        end
      end
    end
  end
end
