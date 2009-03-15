module Rack
  module Mount
    class Route
      class SegmentString < String
        SEPARATORS   = %w( / . ? )
        PARAM_REGEXP = /^:(\w+)$/
        GLOB_REGEXP  = /^\\\*(\w+)$/
        SEGMENT_REGEXP = /[^\/\.\?]+|[\/\.\?]/

        def initialize(str, requirements = {})
          raise ArgumentError unless str.is_a?(String)
          str = str.dup
          prepand_slash!(str)
          @requirements = requirements || {}
          super(str)
        end

        def to_regexp
          @regexp ||= begin
            names = []

            re = scan(SEGMENT_REGEXP).map { |segment|
              next if segment == ""
              segment = Regexp.escape(segment)

              if segment =~ PARAM_REGEXP
                names << $1
                "(#{@requirements[$1.to_sym] || "[^#{SEPARATORS.join}]+"})"
              elsif segment =~ GLOB_REGEXP
                names << $1
                "(.*)"
              else
                segment
              end
            }.compact.join

            RegexpWithNamedGroups.new("^#{re}$", names)
          end
        end

        def names
          to_regexp.names
        end

        private
          def prepand_slash!(str)
            str.replace("/#{str}") unless str =~ /^\//
          end
      end
    end
  end
end
