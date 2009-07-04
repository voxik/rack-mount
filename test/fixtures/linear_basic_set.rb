module ForceLinearGraph
  private
    def generation_keys
      @generation_keys ||= []
    end

    def recognition_keys
      @recognition_keys ||= []
    end
end

class << Rack::Mount::RouteSet
  def new_with_linear_graph(*args, &block)
    new_with_module(ForceLinearGraph, *args, &block)
  end
end

LinearBasicSet = Rack::Mount::RouteSet.new_with_linear_graph(&BasicSetMap)
