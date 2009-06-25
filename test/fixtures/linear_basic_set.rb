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
    @included_modules.push(ForceLinearGraph)
    new(*args, &block)
  ensure
    @included_modules.delete(ForceLinearGraph)
  end
end

LinearBasicSet = Rack::Mount::RouteSet.new_with_linear_graph(&BasicSetMap)
