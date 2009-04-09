module Rack
  module Mount
    class Route
      module Recognition
        def initialize(*args)
          super

          recognizer = @path.is_a?(Regexp) ?
            RegexpWithNamedGroups.new(@path, @requirements) :
            Utils.convert_segment_string_to_regexp(@path, @requirements)

          @recognizer = recognizer.to_regexp
          @recognizer.freeze

          @segment_keys = Utils.extract_static_segments(@recognizer).freeze

          @indexed_params = {}
          @recognizer.named_captures.each { |k, v|
            @indexed_params[k.to_sym] = v.last - 1
          }
          @indexed_params.freeze
        end

        def call(env)
          method = env[Const::REQUEST_METHOD]
          path = env[Const::PATH_INFO]

          if (@method.nil? || method == @method) && path =~ @recognizer
            routing_args, param_matches = @defaults.dup, $~.captures
            @indexed_params.each { |k, i|
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

        def first_segment
          @segment_keys[0]
        end

        def second_segment
          @segment_keys[1]
        end
      end
    end
  end
end
