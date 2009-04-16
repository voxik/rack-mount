module EnvGenerator
  def env_for(n, *args)
    env = Rack::MockRequest.env_for(*args).freeze
    envs = []
    n.times { envs << env.dup }
    envs
  end
  module_function :env_for
end
