module Rack::Mount
  module Recognition
    module CodeGeneration #:nodoc:
      def _expired_call(env) #:nodoc:
        raise 'route set not finalized'
      end

      def rehash
        super
        optimize_call!
      end

      private
        def expire!
          class << self
            undef :call
            alias_method :call, :_expired_call
          end

          super
        end

        def optimize_container_iterator(container)
          body = []

          container.each_with_index { |route, i|
            body << "route = self[#{i}]"
            body << 'routing_args = route.defaults.dup'

            conditions = []
            route.conditions.each do |method, condition|
              b = []
              b << "if m = req.#{method}.match(#{condition.inspect})"
              b << 'matches = m.captures' if route.named_captures[method].any?
              b << 'p = nil' if route.named_captures[method].any?
              b << route.named_captures[method].map { |k, j| "routing_args[#{k.inspect}] = Utils.unescape_uri(p) if p = matches[#{j}]" }.join('; ')
              b << 'true'
              b << 'end'
              conditions << "(#{b.join('; ')})"
            end

            body << <<-RUBY
              if #{conditions.join(' && ')}
                env[#{@parameters_key.inspect}] = routing_args
                response = route.app.call(env)
                return response unless response[0].to_i == 417
              end
            RUBY
          }

          container.instance_eval(<<-RUBY, __FILE__, __LINE__)
            def optimized_each(req)
              env = req.env
              #{body.join("\n")}
              nil
            end
          RUBY
        end

        def optimize_call!
          cache = false
          keys = @recognition_keys.map { |key|
            if key.is_a?(Array)
              cache = true
              key.call_source(:cache, :req)
            else
              "req.#{key}"
            end
          }.join(', ')

          instance_eval(<<-RUBY, __FILE__, __LINE__)
            undef :call
            def call(env)
              set_expectation = env[EXPECT] != '100-continue'
              env[EXPECT] = '100-continue' if set_expectation
              env[PATH_INFO] = Utils.normalize_path(env[PATH_INFO])

              req = #{@request_class.name}.new(env)
              #{'cache = {}' if cache}

              container = @recognition_graph[#{keys}]
              optimize_container_iterator(container) unless container.respond_to?(:optimized_each)
              container.optimized_each(req) ||
                (set_expectation ?
                  [404, {'Content-Type' => 'text/html'}, ['Not Found']] :
                  [417, {'Content-Type' => 'text/html'}, ['Expectation failed']])
            ensure
              env.delete(EXPECT) if set_expectation
            end
          RUBY
        end
    end
  end
end
