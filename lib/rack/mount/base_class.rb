module Rack
  module Mount
    class BaseClass
      def self.include(mod)
        (@included_modules ||= []) << mod
      end

      def self.new(*args, &block)
        obj = allocate
        @included_modules.each { |mod| obj.extend(mod) }
        obj.send(:initialize, *args, &block)
        obj
      end
    end
  end
end
