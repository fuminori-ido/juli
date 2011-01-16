require 'rake'
require 'rake/testtask'
require 'rake/rdoctask'

juli_parser_rb        = 'lib/juli/parser.tab.rb'
juli_line_parser_rb   = 'lib/juli/line_parser.tab.rb'
parsers               = [juli_parser_rb, juli_line_parser_rb]
test_conf_outout_top  = 'test/html'

task :default => parsers

file juli_parser_rb => 'lib/juli/parser.y' do |t|
  sh "racc #{t.prerequisites[0]}"
end

file juli_line_parser_rb => 'lib/juli/line_parser.y' do |t|
  sh "racc #{t.prerequisites[0]}"
end

Rake::TestTask.new('test' => parsers) do |t|
  t.libs    << 'test'
  t.pattern = 'test/**/*_test.rb'
  t.verbose = true
end

Rake::RDocTask.new('doc') do |t|
  t.rdoc_dir  = 'doc/app'
  t.title     = 'juli API'
  t.options  << '--line-numbers'  << '--inline-source' <<
                '--charset'       << 'utf-8'
  t.rdoc_files.include('doc/README_FOR_API.txt')
  t.rdoc_files.include('lib/**/*.rb')
  t.rdoc_files.include('bin/juli')
end

desc 'clean working files'
task :clean do
  sh "find . -name '*~' -exec rm {} \\;"
  sh 'rm', '-rf', *[parsers, test_conf_outout_top].flatten
end