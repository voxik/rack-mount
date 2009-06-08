module Rack
  module Mount
    module Recognition
      module Condition #:nodoc:
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

        def freeze
          named_captures
          super
        end
      end
    end
  end
end
