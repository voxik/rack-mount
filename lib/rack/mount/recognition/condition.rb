module Rack
  module Mount
    module Recognition
      module Condition #:nodoc:
        def match!(value, params)
          if value =~ to_regexp
            matches = $~.captures
            named_captures.each { |k, i|
              if v = matches[i]
                params[k] = v
              end
            }
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
