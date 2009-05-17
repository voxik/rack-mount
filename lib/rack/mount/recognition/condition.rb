module Rack
  module Mount
    module Recognition
      module Condition #:nodoc:
        def match!(value, env, params)
          if value =~ to_regexp
            matches = $~.captures
            named_captures.each { |k, i|
              if v = matches[i]
                params[k] = v
              end
            }
            if is_a?(PathCondition)
              env[Const::PATH_INFO] = Utils.normalize_path(env[Const::PATH_INFO].sub($~.to_s, Const::EMPTY_STRING))
              env[Const::PATH_INFO] = Const::EMPTY_STRING if env[Const::PATH_INFO] == Const::SLASH
              env[Const::SCRIPT_NAME] = Utils.normalize_path("#{env[Const::SCRIPT_NAME]}#{$~.to_s}")
            end
            true
          else
            false
          end
        end

        def freeze
          named_captures
          super
        end

        private
          # Maps named captures to their capture index
          # #=> { :controller => 0, :action => 1, :id => 2, :format => 4 }
          def named_captures
            @named_captures ||= begin
              named_captures = {}
              @pattern.named_captures.each { |k, v|
                named_captures[k.to_sym] = v.last - 1
              }
              named_captures.freeze
            end
          end
      end
    end
  end
end
