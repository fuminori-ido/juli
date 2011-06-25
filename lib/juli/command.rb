require 'juli/util'
require 'juli/parser.tab'
require 'juli/command/recent_update'

module Juli
  # This is a top level module for juli(1) command execution.
  # Each juli(1) command corresponds to each method here.
  module Command
    class Error < Exception; end

    # top level command execution.  command_str will be checked and
    # dispatched to each method.
    def run(command_str, opts = {})
      case command_str
      when 'init';          init(opts)
      when 'gen';           gen(opts)
      when 'sitemap';       sitemap(opts)
      when 'recent_update'; Juli::Command::RecentUpdate.new.run(opts)
      else
        STDERR.print "Unknown juli command: '#{command_str}'\n\n", usage, "\n"
        raise Error
      end
    end

OUTPUT_TOP_COMMENT = <<EOM

# Specify output top directory (default = ../html).

EOM
TEMPLATE_COMMENT = <<EOM

# Specify html template when generating (default = 'default.html', which 
# means that RUBY_LIB/juli/template/default.html is used).
#
# Current available templates are under RUBY_LIB/juli/template/, where
# RUBY_LIB is is the directory which juli library is installed
# (e.g. /usr/local/lib/ruby/site_ruby/1.8/).
#
# (>= v1.01.00) You can put your customized template under JULI_REPO/.juli/
# rather than ruby standard library directory.  For example,
# if you want to use your customized template 'blue_ocean.html',
# create it under JULI_REPO/ and specify it at config as follows:
#
#   $ cp RUBY_LIB/juli/template/default.html JULI_REPO/.juli/blue_ocean.html
#   (edit JULI_REPO/.juli/blue_ocean.html as you like)
#   (edit JULI_REPO/.juli/config as follows:
#
#   template: blue_ocean.html
#
# (>= v1.02.00) File extention (e.g. .html) is required in this config.
# -t option at 'juli gen' command line execution can be also supported.
# 

EOM
EXT_COMMENT = <<EOM

# generating file extention (default = .shtml).
# The reason why '.shtml' is because to use SSI (server side include)
# for recent_update.  Of course, it depends on web-server configuration and
# you may not use SSI.  In such a case, you can change to '.html'.

EOM
    # init does:
    #
    # 1. create juli-repository at the current directory, if not yet.
    # 1. create config file under the juli-repo, if not yet.
    #    This stores juli-repo dependent information.
    # 1. if parameters are specified, store it in config file under juli-repo.
    #
    # === OPTIONS
    # -o output_top
    # -t template
    # -e ext
    def init(opts)
      if !File.directory?(Juli::REPO)
        FileUtils.mkdir(Juli::REPO)
      else
        STDERR.print "WARN: juli-repo is already created\n"
      end

      config_file = File.join(Juli::REPO, 'config')
      if !File.exist?(config_file)
        File.open(config_file, 'w') do |f|
          f.print "# put juli-repo config here.\n\n"
          f.print OUTPUT_TOP_COMMENT
          write_config(f, 'output_top', opts[:o])
          f.print TEMPLATE_COMMENT
          write_config(f, 'template',   opts[:t])
          f.print EXT_COMMENT
          write_config(f, 'ext',        opts[:e])
        end
      else
        STDERR.print "WARN: config file is already created\n"
      end
    end

    # generate command
    #
    # === OPTIONS
    # -g generator::  specify generator
    # -f::            force update
    # -t template::   specify template
    def gen(opts)
      o = opts.dup
      o.delete(:g)
      # executes each generator's init here:
      v = visitor(opts[:g]).new(o)

      if ARGV.empty?
        print "bulk mode\n"
        v.run_bulk
      else
        for file in ARGV do
          Juli::Parser.new.parse(file, v)
        end
      end
    end

    # generate $JULI_REPO/sitemap.html
    def sitemap(opts)
      Dir.chdir(juli_repo) {
        outdir = File.join(conf['output_top'])
        FileUtils.mkdir(outdir) if !File.directory?(outdir)
        body = ''
        for textfile in Dir.glob('**/*.txt').sort do
          html = textfile.gsub(/.txt$/, conf['ext'])
          body += sprintf("<a href='%s'>%s</a><br/>\n",
                      textfile.gsub(/.txt$/, conf['ext']),  # url
                      textfile.gsub(/.txt$/, ''))           # label
        end

      title       = 'Sitemap'
      prototype   = 'prototype.js'
      javascript  = 'juli.js'
      stylesheet  = 'juli.css'
      erb         = ERB.new(File.read(File.join(Juli::TEMPLATE_PATH,
                        'sitemap.html')))
      out_path    = 'sitemap' + conf['ext']
      File.open(File.join(outdir, out_path), 'w') do |f|
        f.write(erb.result(binding))
      end
      }
    end

  private
    def write_config(f, key, value)
      if value
        f.printf("%s: %s\n", key, value)
      end
    end
  end
end
