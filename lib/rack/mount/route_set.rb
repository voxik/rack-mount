module Rack
  module Mount
    class RouteSet
      autoload :Generation, 'rack/mount/route_set/generation'
      autoload :Recognition, 'rack/mount/route_set/recognition'

      DEFAULT_OPTIONS = {
        :optimize => false,
        :keys => [:method, :first_segment]
      }.freeze

      module Base
        def initialize(options = {})
          @options = DEFAULT_OPTIONS.dup.merge!(options)
          @keys = @options.delete(:keys)

          if @options[:optimize]
            extend Optimizations::RouteSet
          end

          if block_given?
            yield self
            freeze
          end
        end

        def add_route(app, options = {})
          Route.new(app, options)
        end
      end
      include Base

      include Generation, Recognition
    end
  end
end
