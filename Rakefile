require 'rake/testtask'
require 'rake/extensiontask'

task :default => :test

Rake::TestTask.new do |t|
  t.libs.push('lib', 'test')
  t.test_files = FileList['test/**/*_test.rb']
  t.verbose = true
end

Rake::ExtensionTask.new do |ext|
  ext.name = 'nested_set_ext'
  ext.ext_dir = 'ext/rack/mount'
  ext.lib_dir = 'lib/rack/mount'
end
