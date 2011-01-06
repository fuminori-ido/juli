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

Rake::RDocTask.new('doc') do |t|
  t.rdoc_dir  = 'doc/app'
  t.title     = 'juli API'
  t.options  << '--line-numbers'  << '--inline-source' <<
                '--charset'       << 'utf-8'
  t.rdoc_files.include('doc/README_FOR_APP')
  t.rdoc_files.include('lib/**/*.rb')
  t.rdoc_files.include('bin/juli')
end