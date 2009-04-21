require 'active_support/inflector'
require 'merb-core/dispatch/router'
require 'rack/request'

module Rack
  module Mount
    class RouteSet
      def prepare(*args, &block)
        Mappers::Merb.new(self).prepare(*args, &block)
        freeze
      end
    end

    module Mappers
      class Merb
        class ::Merb::Router::Behavior
          def to_route
            raise Error, 'The route has already been committed.' if @route

            controller = @params[:controller]

            if prefixes = @options[:controller_prefix]
              controller ||= ':controller'

              prefixes.reverse_each do |prefix|
                break if controller =~ %r{^/(.*)} && controller = $1
                controller = "#{prefix}/#{controller}"
              end
            end

            @params.merge!(:controller => controller.to_s.gsub(%r{^/}, '')) if controller

            identifiers = @identifiers.sort { |(first,_),(sec,_)| first <=> sec || 1 }

            Thread.current[:merb_routes] << [
              @conditions.dup,
              @params,
              @blocks,
              { :defaults => @defaults.dup, :identifiers => identifiers }
            ]

            self
          end
        end

        class DeferredProc
          def initialize(app, deferred_procs)
            @app, @proc = app, deferred_procs.cache
          end

          def call(env)
            # TODO: Change this to a Merb request
            request = Rack::Request.new(env)
            params  = env[Const::RACK_ROUTING_ARGS]
            result  = @proc.call(request, params)

            if result
              @app.call(env)
            else
              Const::NOT_FOUND_RESPONSE
            end
          end
        end

        class RequestConditions
          def initialize(app, conditions)
            @app, @conditions = app, conditions
          end

          def call(env)
            # TODO: Change this to a Merb request
            request = Rack::Request.new(env)

            @conditions.each do |method, expected|
              unless request.send(method) == expected
                return Const::NOT_FOUND_RESPONSE
              end
            end

            @app.call(env)
          end
        end

        DynamicController = lambda { |env|
          app = ActiveSupport::Inflector.camelize("#{env[Const::RACK_ROUTING_ARGS][:controller]}Controller")
          app = ActiveSupport::Inflector.constantize(app)
          app.call(env)
        }

        attr_accessor :root_behavior

        def initialize(set)
          @set = set
          @root_behavior = ::Merb::Router::Behavior.new.defaults(:action => 'index')
        end

        def prepare(first = [], last = [], &block)
          Thread.current[:merb_routes] = []
          begin
            root_behavior._with_proxy(&block)
            routes = Thread.current[:merb_routes]
            routes.each { |route| add_route(*route) }
            self
          ensure
            Thread.current[:merb_routes] = nil
          end
        end

        def add_route(conditions, params, deferred_procs, options = {})
          new_conditions = {}
          new_conditions[:path] = conditions.delete(:path)[0]
          new_conditions[:method] = conditions.delete(:method)

          requirements = {}
          conditions.each do |k, v|
            if v.is_a?(Regexp)
              requirements[k.to_sym] = conditions.delete(k)
            end
          end

          app = params.has_key?(:controller) ?
            ActiveSupport::Inflector.constantize(ActiveSupport::Inflector.camelize("#{params[:controller]}Controller")) :
            DynamicController

          if deferred_procs.any?
            app = DeferredProc.new(app, deferred_procs.first)
          end

          if conditions.any?
            app = RequestConditions.new(app, conditions)
          end

          @set.add_route(app, new_conditions, requirements, params)
        end
      end
    end
  end
end
