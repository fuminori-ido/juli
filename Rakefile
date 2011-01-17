$LOAD_PATH.insert(0, File.join(File.dirname(__FILE__), 'lib'))

require 'rake'
require 'rake/testtask'
require 'rake/rdoctask'
require 'juli'

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

desc 'build package'
task :dist do
  pkg_name    = "juli-#{Juli::VERSION}"
  work_prefix = "/tmp/#{pkg_name}"
  sh "git archive --format=tar --prefix=#{pkg_name}/ HEAD | gzip >#{work_prefix}.tgz"

  # include racc geneerated files
  FileUtils.mkdir_p work_prefix
  Dir.chdir work_prefix do
    sh "tar zxvf #{work_prefix}.tgz"
    Dir.chdir pkg_name do
      sh 'rake'
    end
    sh "tar zcvf #{work_prefix}.tgz #{pkg_name}"
  end
  FileUtils.rm_rf work_prefix
end

Rake::RDocTask.new('doc') do |t|
  t.rdoc_dir  = 'doc/app'
  t.title     = 'juli API'
  t.options  << '--line-numbers'  << '--inline-source' <<
                '--charset'       << 'utf-8'
  t.rdoc_files.include('doc/README_FOR_API')
  t.rdoc_files.include('lib/**/*.rb')
  t.rdoc_files.include('bin/juli')
end

desc 'clean working files'
task :clean => :clobber_doc do
  sh "find . -name '*~' -exec rm {} \\;"
  sh 'rm', '-rf', *[parsers, test_conf_outout_top, 
      'InstalledFiles', '.config',    # setup.rb generated
      'doc/html'].flatten
end