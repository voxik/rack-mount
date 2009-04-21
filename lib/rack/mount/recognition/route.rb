module Rack
  module Mount
    module Recognition
      module Route
        def initialize(*args)
          super

          @path_keys      = path_keys(@path, %w( / ))
          @named_captures = named_captures(@path)
        end

        def call(env)
          method = env[Const::REQUEST_METHOD]
          path = env[Const::PATH_INFO]

          if (@method.nil? || method == @method) && path =~ @path
            routing_args, param_matches = @defaults.dup, $~.captures
            @named_captures.each { |k, i|
              if v = param_matches[i]
                routing_args[k] = v
              end
            }
            env[Const::RACK_ROUTING_ARGS] = routing_args
            @app.call(env)
          else
            @throw
          end
        end

        def path_keys_at(index)
          @path_keys[index]
        end

        private
          # Keys for inserting into NestedSet
          # #=> ['people', /[0-9]+/, 'edit']
          def path_keys(regexp, separators)
            Utils.extract_static_segments(regexp, separators).freeze
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
