class PathPrefix
  Const = Rack::Mount::Const
  Utils = Rack::Mount::Utils

  def initialize(app, path_prefix = nil)
    @app, @path_prefix = app, /^#{Regexp.escape(path_prefix)}/.freeze
  end

  def call(env)
    original_path_info   = env[Const::PATH_INFO].dup
    original_script_name = env[Const::SCRIPT_NAME].dup

    if env[Const::PATH_INFO] =~ @path_prefix
      env[Const::PATH_INFO].sub!(@path_prefix, Const::EMPTY_STRING)
      env[Const::PATH_INFO] = Utils.normalize_path(env[Const::PATH_INFO])
      env[Const::SCRIPT_NAME] = Utils.normalize_path("#{env[Const::SCRIPT_NAME]}#{$~.to_s}")
    end

    @app.call(env)
  ensure
    env[Const::PATH_INFO]   = original_path_info
    env[Const::SCRIPT_NAME] = original_script_name
  end
end
