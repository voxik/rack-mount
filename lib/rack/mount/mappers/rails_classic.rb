module Rack
  module Mount
    class RouteSet
      def draw(&block)
        Mappers::RailsClassic.new(self).draw(&block)
        freeze
      end
    end

    module Mappers
      class RailsClassic
        class RoutingError < StandardError; end

        NotFound = lambda { |env|
          raise RoutingError, "No route matches #{env["PATH_INFO"].inspect} with #{env.inspect}"
        }

        class Dispatcher
          def initialize(options = {})
            defaults = options[:defaults]
            @app = controller(defaults)
          end

          def call(env)
            app = @app || controller(env[Const::RACK_ROUTING_ARGS])

            # TODO: Rails response is not finalized by the controller
            app.call(env).to_a
          end

          private
            def controller(params)
              if params && params.has_key?(:controller)
                controller = "#{params[:controller].camelize}Controller"
                ActiveSupport::Inflector.constantize(controller)
              end
            end
        end

        attr_reader :named_routes

        def initialize(set)
          @set = set
          @named_routes = {}
        end

        def draw(&block)
          require 'action_controller'
          yield ActionController::Routing::RouteSet::Mapper.new(self)
          @set.add_route(NotFound, :path => /.*/)
          self
        end

        def add_route(path, options = {})
          path = path.gsub(".:format", "(.:format)") if path.is_a?(String)

          if conditions = options.delete(:conditions)
            method = conditions.delete(:method)
          end

          name = options.delete(:name)

          requirements = options.delete(:requirements) || {}
          defaults = {}
          options.each do |k, v|
            if v.is_a?(Regexp)
              requirements[k.to_sym] = options.delete(k)
            else
              defaults[k.to_sym] = options.delete(k)
            end
          end

          app = Dispatcher.new(:defaults => defaults)

          @set.add_route(app, {
            :name => name,
            :path => path,
            :method => method,
            :requirements => requirements,
            :defaults => defaults
          })
        end

        def add_named_route(name, path, options = {})
          options[:name] = name
          add_route(path, options)
        end
      end
    end
  end
end
