module Rack::Mount
  # A mixin that changes the behavior of +include+. Instead of modules
  # being chained as a superclass, they are mixed into the objects
  # metaclass. This allows mixins to be stacked ontop of the instance
  # methods.
  module Mixover
    def self.extended(klass)
      klass.instance_eval do
        @extended_modules = []
      end
    end

    module InstanceMethods #:nodoc:
      def dup
        obj = super
        included_modules = (class << self; included_modules; end) - (class << obj; included_modules; end)
        included_modules.reverse.each { |mod| obj.extend(mod) }
        obj
      end
    end

    # Replaces include with a lazy version.
    def include(*mod)
      extended_modules.push(*mod)
    end

    def extended_modules
      Thread.current[extended_modules_thread_local_key] || @extended_modules
    end

    def new(*args, &block) #:nodoc:
      obj = allocate
      obj.extend(InstanceMethods)
      extended_modules.each { |mod| obj.extend(mod) }
      obj.send(:initialize, *args, &block)
      obj
    end

    # Create a new class without an included module.
    def new_without_module(mod, *args, &block)
      (Thread.current[extended_modules_thread_local_key] = extended_modules.dup).delete(mod)
      new(*args, &block)
    ensure
      Thread.current[extended_modules_thread_local_key] = nil
    end

    # Create a new class temporarily with a module.
    def new_with_module(mod, *args, &block)
      (Thread.current[extended_modules_thread_local_key] = extended_modules.dup).push(*mod)
      new(*args, &block)
    ensure
      Thread.current[extended_modules_thread_local_key] = nil
    end

    private
      def extended_modules_thread_local_key
        "mixover_extended_modules_#{object_id}"
      end
  end
end
