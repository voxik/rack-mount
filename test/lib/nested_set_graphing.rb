module NestedSetGraphing
  def to_graph
    require 'lib/graphviz_ext'

    g = GraphViz::new('G')
    g[:nodesep] = '.05'
    g[:rankdir] = 'LR'

    g.node[:shape] = 'record'
    g.node[:width] = '.1'
    g.node[:height] = '.1'

    g.add_object(@recognition_graph)

    g
  end

  def debug_graph!
    to_graph.output(:path => '/opt/local/bin/', :file => '/tmp/graph.dot')
    system('open /tmp/graph.dot')
  end
end
