module ForceLinearGraph
  private
    def build_generation_keys
      []
    end

    def build_recognition_keys
      []
    end
end

class << Rack::Mount::RouteSet
  def new_with_linear_graph(options = {}, &block)
    set = new_without_optimizations(options, &block)
    set.extend(ForceLinearGraph)
    set.rehash
    set
  end
end

LinearBasicSet = Rack::Mount::RouteSet.new_with_linear_graph(&BasicSetMap)
