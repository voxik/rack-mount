module Rack
  module Mount
    # A mixin that changes the behavior of +include+. Instead of modules
    # being chained as a superclass, they are mixed into the objects
    # metaclass. This allows mixins to be stacked ontop of the instance
    # methods.
    module Mixover
      def include(*mod)
        (@included_modules ||= []).push(*mod)
      end

      def new(*args, &block)
        obj = allocate
        @included_modules.each { |mod| obj.extend(mod) }
        obj.send(:initialize, *args, &block)
        obj
      end
    end
  end
end
