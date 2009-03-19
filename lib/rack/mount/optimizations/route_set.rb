module Rack
  module Mount
    module Optimizations
      module RouteSet
        def freeze
          optimize_keys_for!

          super
        end

        private
          def optimize_keys_for!
            instance_eval(<<-EOS, __FILE__, __LINE__)
              def keys_for(env)
                req = Rack::Mount::Request.new(env)
                return #{@keys.map { |key| "req.#{key}" }.join(", ")}
              end
            EOS
          end
      end
    end
  end
end
