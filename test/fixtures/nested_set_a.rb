NestedSetA = Rack::Mount::RouteSet.new do |set|
  set.add_route(EchoApp, { :path_info => '/ok' }, { :response => 'ok' })
  set.add_route(lambda { |env| [404, {'X-Cascade' => 'pass'}, []] }, { :path_info => '/pass' }, { :response => 'not_found' })
end
