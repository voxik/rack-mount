require 'yaml'

class EchoApp
  def self.call(env)
    [200, {'Content-Type' => 'text/yaml'}, [YAML.dump(env)]]
  end
end
