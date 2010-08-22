require 'graphviz'

class Object
  def to_graph_node
    "node#{object_id}"
  end

  def to_graph_label
    inspect.dot_escape
  end

  def add_to_graph(graph)
    graph.add_node(to_graph_node, :label => to_graph_label)
  end
end

class Array
  def to_graph_label
    "{#{map { |e| e.to_graph_label }.join('|')}}"
  end
end

class String
  DOT_ESCAPE = %w( \\ < > { } )
  DOT_ESCAPE_REGEXP = Regexp.compile("(#{Regexp.union(*DOT_ESCAPE).source})")

  def dot_escape
    gsub(DOT_ESCAPE_REGEXP) {|s| "\\#{s}" }
  end
end

require 'multimap'

class Multimap
  def to_graph_label
    label = []
    @hash.each_key do |key|
      label << "<#{key.to_graph_node}> #{key.to_graph_label}"
    end
    "#{label.join('|')}|<default>"
  end

  def add_to_graph(graph)
    hash_node = super

    @hash.each_pair do |key, container|
      node = container.add_to_graph(graph)
      graph.add_edge({hash_node => key.to_graph_node}, node)
    end

    unless default.nil?
      node = default.add_to_graph(graph)
      graph.add_edge({hash_node => :default}, node)
    end

    hash_node
  end

  def to_graph
    g = GraphViz::new('G')
    g[:nodesep] = '.05'
    g[:rankdir] = 'LR'

    g.node[:shape] = 'record'
    g.node[:width] = '.1'
    g.node[:height] = '.1'

    add_to_graph(g)

    g
  end
end

require 'rack/mount'

class Rack::Mount::RouteSet
  def to_graph
    @recognition_graph.to_graph
  end

  def open_graph!
    output = File.join(Dir::tmpdir, 'graph.png')
    to_graph.output(:png => output)
    system("open #{output}")
  end
end

class Rack::Mount::Route
  def to_graph_label
    @conditions[:path_info].to_graph_label
  end
end
