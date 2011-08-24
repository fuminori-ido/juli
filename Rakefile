$LOAD_PATH.insert(0, File.join(File.dirname(__FILE__), 'lib'))

require 'rake'
require 'rake/testtask'
require 'rdoc/task'
require 'juli'
require 'racc'

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

desc "build package from HEAD with version #{Juli::VERSION}"
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


namespace :doc do
  desc 'generate HTML by juli'
  task :juli do
    sh <<-EOSH
      (cd doc; juli; juli sitemap; juli recent_update)
    EOSH
  end

  desc 'update project doc to SourceForge site'
  task :up => :juli do
    sh <<-EOSH
      cd doc_html/
      find . -type f -exec chmod o+r {} \\;
      find . -type d -exec chmod o+x {} \\;
      rsync -avP --delete -e ssh . fwells00,jjjuli@web.sourceforge.net:htdocs/
    EOSH
  end

  Rake::RDocTask.new('app') do |t|
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
task :clean => ['doc:clobber_app', :'test:coverage:clobber_juli'] do
  sh "find . -name '*~' -exec rm {} \\;"
  sh 'rm', '-rf', *[parsers, test_conf_outout_top, 
      'InstalledFiles', '.config',    # setup.rb generated
      'doc/html'].flatten
end

begin
  require 'rcov/rcovtask'
  $rcov_exist = true
rescue LoadError
  $stderr.puts "rcov is not installed."
end

# set rcov default options
def set_rcov_default(t)
  t.libs << "test"
  t.verbose = true
  t.rcov_opts = ["--charset=utf-8", "--rails"]
  t.rcov_opts << ["-x", ENV["GEM_HOME"]] if ENV["GEM_HOME"] && !ENV["GEM_HOME"].empty?
  t.rcov_opts << ["-x", File.expand_path('.gem', ENV["HOME"])]
end

namespace :test do
  if $rcov_exist
    namespace :coverage do
      Rcov::RcovTask.new(:juli) do |t|
        set_rcov_default(t)
        t.test_files = FileList["test/**/*_test.rb"]
      end
    end
    task :coverage => "test:coverage:juli"
  end
end

