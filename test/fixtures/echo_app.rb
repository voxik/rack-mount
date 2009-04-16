require 'yaml'

EchoApp = lambda { |env|
  [200, {Rack::Mount::Const::CONTENT_TYPE => 'text/yaml'}, [YAML.dump(env)]]
}
