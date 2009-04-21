module Rack
  module Mount
    class RouteSet
      def draw(&block)
        Mappers::RailsClassic.new(self).draw(&block)
        install_helpers
        freeze
      end

      def generate(options, recall = {}, method = :generate)
        named_route = options.delete(:use_route)
        url_for(named_route, options)
      end

      def add_configuration_file(path)
        load(path)
      end

      def load!
      end
      alias reload! load!

      def reload
      end

      def install_helpers(destinations = [ActionController::Base, ActionView::Base], regenerate_code = false)
        Array(destinations).each { |d| d.module_eval { include ActionController::Routing::Helpers } }
        # named_routes.install(destinations, regenerate_code)
      end
    end

    module Mappers
      class RailsClassic
        class RoutingError < StandardError; end

        NotFound = lambda { |env|
          raise RoutingError, "No route matches #{env[Const::PATH_INFO].inspect} with #{env.inspect}"
        }

        class Dispatcher
          def initialize(options = {})
            defaults = options[:defaults]
            @glob_param = options.delete(:glob)
            @app = controller(defaults)
          end

          def call(env)
            params = env[Const::RACK_ROUTING_ARGS]
            app = @app || controller(params)
            merge_default_action!(params)
            split_glob_param!(params) if @glob_param

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

            def merge_default_action!(params)
              params[:action] ||= 'index'
            end

            def split_glob_param!(params)
              params[@glob_param] = params[@glob_param].split('/')
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
          if path.is_a?(String)
            path = path.gsub('.:format', '(.:format)')
            path = optionalize_trailing_dynamic_segments(path)
          end

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

          if path.is_a?(String)
            glob = $1.to_sym if path =~ /\/\*(\w+)$/
            path = Utils.convert_segment_string_to_regexp(path, requirements, %w( / . ? ))
          end

          app = Dispatcher.new(:defaults => defaults, :glob => glob)

          conditions = { :method => method, :path => path }
          @set.add_route(app, conditions, defaults, name)
        end

        def add_named_route(name, path, options = {})
          options[:name] = name
          add_route(path, options)
        end

        private
          def optionalize_trailing_dynamic_segments(path)
            path = (path =~ /^\//) ? path.dup : "/#{path}"
            optional, segments = true, []

            old_segments = path.split('/')
            old_segments.shift
            length = old_segments.length

            old_segments.reverse.each_with_index do |segment, index|
              if optional && !(segment =~ /^:\w+$/) && !(segment =~ /^:\w+\(\.:format\)$/)
                optional = false
              end

              if optional && index < length - 1
                segments.unshift('(/', segment)
                segments.push(')')
              else
                segments.unshift('/', segment)
              end
            end

            segments.join
          end
      end
    end
  end
end
