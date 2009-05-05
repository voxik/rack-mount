require 'strscan'

module Rack
  module Mount
    module Recognition
      module Route #:nodoc:
        attr_writer :throw, :parameters_key

        def initialize(*args)
          super

          @throw          = Const::NOT_FOUND_RESPONSE
          @parameters_key = Const::RACK_ROUTING_ARGS
          @path_keys      = @conditions[:path].keys if @conditions.has_key?(:path)
          @keys           = generate_keys
          @named_captures = @conditions.has_key?(:path) ? named_captures(@conditions[:path].to_regexp) : []
        end

        def call(env)
          method = env[Const::REQUEST_METHOD]
          path = Utils.normalize(env[Const::PATH_INFO])

          if (!@conditions.has_key?(:method) || method =~ @conditions[:method].to_regexp) &&
               (!@conditions.has_key?(:path) || path =~ @conditions[:path].to_regexp)
            routing_args = @defaults.dup
            param_matches = $~.captures if $~
            @named_captures.each { |k, i|
              if v = param_matches[i]
                routing_args[k] = v
              end
            }
            env[@parameters_key] = routing_args
            @app.call(env)
          else
            @throw
          end
        end

        KEYS = []

        def method
          @conditions.has_key?(:method) ? @conditions[:method].key : nil
        end
        KEYS << :method

        def path_keys_at(index)
          @path_keys[index]
        end

        attr_reader :keys

        10.times do |n|
          module_eval(<<-EOS, __FILE__, __LINE__)
            def path_keys_at_#{n}
              @path_keys[#{n}] if @path_keys
            end
            KEYS << :"path_keys_at_#{n}"
          EOS
        end

        KEYS.freeze

        private
          def generate_keys
            KEYS.inject({}) { |keys, k|
              if v = send(k)
                keys[k] = v
              end
              keys
            }
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
