require 'active_support/inflector'

module Rack
  module Mount
    class RouteSet
      def new_draw(&block)
        mapper = Mappers::RailsDraft.new(self)
        mapper.instance_eval(&block)
        add_route(Mappers::RailsDraft::NotFound, :path => /.*/)
        freeze
      end
    end

    module Mappers
      class RailsDraft
        class RoutingError < StandardError; end

        NotFound = lambda { |env|
          raise RoutingError, "No route matches #{env[Const::PATH_INFO].inspect} with #{env.inspect}"
        }

        DynamicController = lambda { |env|
          app = "#{env[Const::RACK_ROUTING_ARGS][:controller].camelize}Controller"
          app = ActiveSupport::Inflector.constantize(app)
          app.call(env)
        }

        def initialize(set)
          require 'action_controller'
          @set = set
          @scope_stack = []
        end

        def get(path, options = {})
          match(path, options.merge(:via => :get))
        end

        def post(path, options = {})
          match(path, options.merge(:via => :post))
        end

        def put(path, options = {})
          match(path, options.merge(:via => :put))
        end

        def delete(path, options = {})
          match(path, options.merge(:via => :delete))
        end

        def match(path, options = {}, &block)
          if block
            @scope_stack.push(options.merge({:path => path}))
            begin
              instance_eval(&block)
            ensure
              @scope_stack.pop
            end

            return
          end

          new_options = {}
          method = options.delete(:via)
          requirements = options.delete(:constraints) || {}
          defaults = {}

          if path.is_a?(Symbol) && scope_options.has_key?(:path)
            defaults[:action] = path.to_s
            path = scope_options[:path]
          elsif path.is_a?(Regexp)
          elsif path.nil?
          else
            scoped_path = @scope_stack.map { |scope| scope[:path] }.compact
            scoped_path << path if path.is_a?(String)
            scoped_path.map! { |path| path =~ /^\// ? path : "/#{path}" }
            path = scoped_path.join
          end

          if path.is_a?(String)
            path = optionalize_trailing_dynamic_segments(path)
          end

          if controller = scope_options[:controller]
            defaults[:controller] = controller.to_s
          end

          if to = options.delete(:to)
            controller, action = to.to_s.split('#')

            if controller && action && defaults[:controller]
              defaults[:controller] = "#{defaults[:controller]}#{controller}"
              defaults[:action] = action
            elsif !action && defaults[:controller]
              defaults[:action] = controller if controller
            else
              defaults[:controller] = controller if controller
              defaults[:action] = action if action
            end
          end

          app = defaults.has_key?(:controller) ?
            ActiveSupport::Inflector.constantize("#{defaults[:controller].camelize}Controller") :
            DynamicController

          if path.is_a?(String)
            path = Utils.convert_segment_string_to_regexp(path, requirements, %w( / . ? ))
          end
          conditions = { :method => method, :path => path }
          @set.add_route(app, conditions, defaults)
        end

        def controller(controller, &block)
          @scope_stack.push(:controller => controller)
          begin
            instance_eval(&block)
          ensure
            @scope_stack.pop
          end
        end

        def namespace(namespace, &block)
          @scope_stack.push(:path => namespace.to_s, :controller => "#{namespace}/")
          begin
            instance_eval(&block)
          ensure
            @scope_stack.pop
          end
        end

        def resources(*entities, &block)
          options = entities.extract_options!
          entities.each { |entity| map_resource(entity, options.dup, &block) }
        end

        private
          def scope_options
            options = {}
            @scope_stack.each { |opts| options.merge!(opts) }
            options
          end

          def map_resource(entities, options = {}, &block)
            resource = ActionController::Resources::Resource.new(entities, options)

            get(resource.path, :to => "#{resource.controller}#index")
            post(resource.path, :to => "#{resource.controller}#create")
            get(resource.new_path, :to => "#{resource.controller}#new")
            get("#{resource.member_path}/edit", :to => "#{resource.controller}#edit")
            get(resource.member_path, :to => "#{resource.controller}#show")
            put(resource.member_path, :to => "#{resource.controller}#update")
            delete(resource.member_path, :to => "#{resource.controller}#destroy")
          end

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
