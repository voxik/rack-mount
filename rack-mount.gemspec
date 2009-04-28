Gem::Specification.new do |s|
  s.name     = 'rack-mount'
  s.version  = '0.0.1'
  s.date     = '2009-04-28'
  s.summary  = 'Stackable dynamic tree based Rack router'
  s.description = s.summary
  s.email    = 'josh@joshpeek.com'
  s.homepage = 'http://github.com/josh/rack-mount'
  s.has_rdoc = true
  s.authors  = ["Joshua Peek"]
  s.files    = [
    "lib/rack/mount.rb",
    "lib/rack/mount/const.rb",
    "lib/rack/mount/exceptions.rb",
    "lib/rack/mount/generation.rb",
    "lib/rack/mount/generation/optimizations.rb",
    "lib/rack/mount/generation/route.rb",
    "lib/rack/mount/generation/route_set.rb",
    "lib/rack/mount/mappers/merb.rb",
    "lib/rack/mount/mappers/rails_classic.rb",
    "lib/rack/mount/mappers/rails_draft.rb",
    "lib/rack/mount/mappers/simple.rb",
    "lib/rack/mount/nested_set.rb",
    "lib/rack/mount/path_prefix.rb",
    "lib/rack/mount/recognition.rb",
    "lib/rack/mount/recognition/route.rb",
    "lib/rack/mount/recognition/route_set.rb",
    "lib/rack/mount/regexp_with_named_groups.rb",
    "lib/rack/mount/request.rb",
    "lib/rack/mount/route.rb",
    "lib/rack/mount/route_set.rb",
    "lib/rack/mount/utils.rb",
    "rails/init.rb"
  ]
  s.extra_rdoc_files = %w[README.rdoc MIT-LICENSE]
  s.require_paths = %w[lib]
  s.add_dependency 'rack', '> 1.0.0'
end
