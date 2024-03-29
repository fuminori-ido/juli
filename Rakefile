#require 'byebug'; byebug
require "bundler/gem_tasks"

$LOAD_PATH.insert(0, File.join(File.dirname(__FILE__), 'lib'))

require 'rake'
require 'rake/testtask'
gem 'rdoc'
require 'rdoc/task'
require 'juli'
require 'racc'

juli_parser_rb        = 'lib/juli/parser.tab.rb'
juli_line_parser_rb   = 'lib/juli/line_parser.tab.rb'
parsers               = [juli_parser_rb, juli_line_parser_rb]
test_conf_outout_top  = 'test/html'

task build: parsers

file juli_parser_rb => 'lib/juli/parser.y' do |t|
  sh "racc -v -g #{t.prerequisites[0]}"
end

file juli_line_parser_rb => 'lib/juli/line_parser.y' do |t|
  sh "racc #{t.prerequisites[0]}"
end

Rake::TestTask.new(test: parsers) do |t|
  t.libs    << 'test'
  t.pattern = 'test/**/*_test.rb'
  t.verbose = true
end

desc "build with parser.tab under right permission(022)"
task :dist do
  old_umask = File.umask(022); begin
    curr_dir    = Dir.pwd
    pkg_name    = "juli-#{Juli::VERSION}"
    work_prefix = "/tmp/#{pkg_name}-#{$$}"

    # include racc geneerated files
    FileUtils.mkdir_p work_prefix
    Dir.chdir work_prefix do
      sh "git clone --local --depth 1 #{curr_dir} juli"
      Dir.chdir 'juli' do
        sh 'rake'
        sh 'rake build'
      end
    end
    FileUtils.mv "#{work_prefix}/juli/pkg/#{pkg_name}.gem", 'pkg/'
    FileUtils.rm_rf work_prefix
  end; File.umask(old_umask)
end

namespace :doc do
  desc 'generate HTML by juli'
  task :juli do
    sh <<-EOSH
      (cd doc; ../bin/juli; ../bin/juli sitemap; ../bin/juli recent_update)
      (cd doc; ../bin/juli gen -g slidy -t slidy.html slidy.txt)
      (cd doc; ../bin/juli gen -g takahashi_method -t takahashi_method.html -o ../doc_html/slidy_takahashi_method_version.shtml slidy.txt)
    EOSH
  end

  desc 'update project doc to SourceForge site'
  task up: :juli do
    sh <<-EOSH
      cd doc_html/
      find . -type f -exec chmod o+r {} \\;
      find . -type d -exec chmod o+x {} \\;
      rsync -avP --delete -e ssh . fwells00,jjjuli@web.sourceforge.net:htdocs/
    EOSH
  end

  RDoc::Task.new('app') do |t|
    t.rdoc_dir  = 'doc/app'
    t.title     = 'juli API'
    t.options  << '--line-numbers'  << '--inline-source' <<
                  '--charset'       << 'utf-8'
    t.rdoc_files.include('doc/README_FOR_API')
    t.rdoc_files.include('lib/**/*.rb')
    t.rdoc_files.include('bin/juli')
  end
end

desc 'clean working files'
task clean: ['doc:clobber_app'] do
  sh "find . -name '*~' -exec rm {} \\;"
  sh 'rm', '-rf', *[parsers, test_conf_outout_top, 
      'InstalledFiles', '.config',    # setup.rb generated
      'doc/html'].flatten
end
