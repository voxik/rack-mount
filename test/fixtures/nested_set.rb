NestedSet = Rack::Mount::RouteSet.new do |set|
  set.add_route(EchoApp, { :path_info => '/ok' }, {})
  set.add_route(lambda { |env| [404, {'X-Cascade' => 'pass'}, []] }, { :path_info => '/pass' }, { :cascaded => 'yes' })
end
