require 'active_support/inflector'

module Rack
  module Mount
    module Mappers
      class RailsDraft
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
          if block_given?
            begin
              @scope_stack.push(options.merge({:path => path}))
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
          end

          if controller = scope_options[:controller]
            defaults[:controller] = controller.to_s
          end

          if to = options.delete(:to)
            controller, action = to.to_s.split("#")

            if defaults[:controller]
              defaults[:action] = controller if controller
            else
              defaults[:controller] = controller if controller
              defaults[:action] = action if action
            end
          end

          if defaults.has_key?(:controller)
            app = "#{defaults[:controller].camelize}Controller"
            app = ActiveSupport::Inflector.constantize(app)
          else
            app = lambda { |env|
              app = "#{env["rack.routing_args"][:controller].camelize}Controller"
              app = ActiveSupport::Inflector.constantize(app)
              app.call(env)
            }
          end

          @set.add_route({
            :app => app,
            :path => path,
            :method => method,
            :requirements => requirements,
            :defaults => defaults
          })
        end

        def controller(controller, &block)
          @scope_stack.push({:controller => controller})
          instance_eval(&block)
        ensure
          @scope_stack.pop
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
      end
    end
  end
end
