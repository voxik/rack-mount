require 'strscan'

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
          @named_captures = @conditions.has_key?(:path) ? named_captures(@conditions[:path].to_regexp) : []
        end

        def call(env)
          req = Request.new(env)

          routing_args = @defaults.dup
          if @conditions.all? { |method, condition|
            if req.send(method) =~ condition.to_regexp
              param_matches = $~.captures
              @named_captures.each { |k, i|
                if v = param_matches[i]
                  routing_args[k] = v
                end
              }
            end
          }
            env[@parameters_key] = routing_args
            @app.call(env)
          else
            @throw
          end
        end

        private
          def generate_keys
            Mount::Route::VALID_CONDITIONS.inject({}) do |keys, method|
              if @conditions.has_key?(method)
                keys.merge!(@conditions[method].keys)
              end
              keys
            end
          end

          # Maps named captures to their capture index
          # #=> { :controller => 0, :action => 1, :id => 2, :format => 4 }
          def named_captures(regexp)
            named_captures = {}
            regexp.named_captures.each { |k, v|
              named_captures[k.to_sym] = v.last - 1
            }
            named_captures.freeze
          end
      end
    end
  end
end
