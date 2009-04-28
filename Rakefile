require 'rubygems'
require 'rake'
require 'rake/testtask'
require 'rake/packagetask'
require 'rake/gempackagetask'

# load gemspec like github's gem builder to surface any SAFE issues.
Thread.new {
  require 'rubygems/specification'
  $spec = eval("$SAFE=3\n#{File.read('rack-mount.gemspec')}")
}.join

Rake::GemPackageTask.new($spec) do |package|
  package.gem_spec = $spec
end

begin
  require 'hanna/rdoctask'
rescue LoadError
  require 'rake/rdoctask'
end

Rake::RDocTask.new { |rdoc|
  rdoc.rdoc_dir = 'doc'
  rdoc.title    = 'Rack::Mount'
  rdoc.options << '--line-numbers' << '--inline-source'
  rdoc.options << '--charset' << 'utf-8'

  rdoc.rdoc_files.include('README.rdoc')
  rdoc.rdoc_files.include('lib/**/*.rb')
  rdoc.rdoc_files.exclude('lib/rack/mount/mappers/*.rb')
}

task :default => :test

Rake::TestTask.new do |t|
  t.libs.push('lib', 'test')
  t.test_files = FileList['test/**/*_test.rb']
  t.verbose = true
end

begin
  gem 'rake-compiler'
  require 'rake/extensiontask'

  Rake::ExtensionTask.new do |ext|
    ext.name = 'nested_set_ext'
    ext.ext_dir = 'ext/rack/mount'
    ext.lib_dir = 'lib/rack/mount'
  end
rescue Gem::LoadError
end
