require 'rake/testtask'

task :default => :test

Rake::TestTask.new do |t|
  t.libs << 'test'
  t.warning = true
end


task :compile => [
  'lib/rack/mount/strexp/parser.rb',
  'lib/rack/mount/strexp/tokenizer.rb'
]

file 'lib/rack/mount/strexp/parser.rb' => 'lib/rack/mount/strexp/parser.y' do |t|
  sh "racc -l -o #{t.name} #{t.prerequisites.first}"
  sh "sed -i '' -e 's/    end   # module Mount/  end   # module Mount/' #{t.name}"
  sh "sed -i '' -e 's/  end   # module Rack/end   # module Rack/' #{t.name}"
end

file 'lib/rack/mount/strexp/tokenizer.rb' => 'lib/rack/mount/strexp/tokenizer.rex' do |t|
  sh "rex -o #{t.name} #{t.prerequisites.first}"
end

namespace :vendor do
  task :update => [:update_regin]

  task :update_regin do
    system 'git clone git://github.com/josh/regin.git'
    FileUtils.rm_rf('lib/rack/mount/vendor/regin')
    FileUtils.cp_r('regin/lib', 'lib/rack/mount/vendor/regin')
    FileUtils.rm_rf('regin')

    FileUtils.rm_rf('lib/rack/mount/vendor/regin/regin/parser.y')
    FileUtils.rm_rf('lib/rack/mount/vendor/regin/regin/tokenizer.rex')
  end
end
