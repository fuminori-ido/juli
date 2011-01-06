require 'rake'
require 'rake/testtask'
require 'rake/rdoctask'

task :default => 'lib/juli/juli_parser.tab.rb'

file 'lib/juli/juli_parser.tab.rb' => 'lib/juli/juli_parser.y' do |t|
  sh "racc #{t.prerequisites[0]}"
end

Rake::TestTask.new do |t|
  t.libs    << 'test'
  t.pattern = 'test/**/*_test.rb'
  t.verbose = true
end
