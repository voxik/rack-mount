require 'yaml'

EchoApp = lambda { |env|
  [200, {'Content-Type' => 'text/yaml'}, [YAML.dump(env)]]
}
