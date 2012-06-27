require 'juli/util'
require 'juli/parser.tab'
Dir.glob(File.join(File.dirname(__FILE__), 'command/*.rb')){|sub_command_file|
  require sub_command_file
}

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
      when 'sitemap';       Juli::Command::Sitemap.new.run(opts)
      when 'recent_update'; Juli::Command::RecentUpdate.new.run(opts)
      when 'tag';           Juli::Command::Tag.new.run(opts)
      else
        STDERR.print "Unknown juli command: '#{command_str}'\n\n", usage, "\n"
        raise Error
      end
    end

OUTPUT_TOP_COMMENT = <<EOM
# Locale(default = en)

#locale: en


# Juli-repo config file.
#
# This is YAML format.
#
# Starting '#' at each line means just comment.
# You can delete these comments.

# Specify output top directory (default = ../html).

EOM
TEMPLATE_COMMENT = <<EOM

# Specify html template when generating (default = 'default.html', which 
# means that RUBY_LIB/juli/template/default.html is used).
#
# Current available templates are under RUBY_LIB/juli/template/, where
# RUBY_LIB is is the directory which juli library is installed
# (e.g. /usr/local/lib/ruby/site_ruby/1.9/).
#
# You can put your customized template under JULI_REPO/.juli/
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
# File extention (e.g. .html) is required in this config.
# -t option at 'juli gen' command line execution can be also supported.
# 

EOM
EXT_COMMENT = <<EOM

# Generated file's extention (default = .shtml).
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
          f.print OUTPUT_TOP_COMMENT
          write_config(f, 'output_top', opts[:o])
          f.print TEMPLATE_COMMENT
          write_config(f, 'template',   opts[:t])
          f.print EXT_COMMENT
          write_config(f, 'ext',        opts[:e])
          write_macro_conf(f)
          write_helper_conf(f)
        end
      else
        STDERR.print "WARN: config file is already created\n"
      end
    end

    # generate command
    #
    # === OPTIONS
    # -g generator::    specify generator
    # -f::              force update
    # -t template::     specify template
    # -o output_path::  specify output file path (only non-bulk-mode)
    def gen(opts)
      o = opts.dup
      o.delete(:g)
      # executes each generator's init here:
      v = visitor(opts[:g]).new(o)

      if ARGV.empty?
        print "bulk mode\n"
        if opts[:o]
          STDERR.print "ERROR: -o #{opts[:o]} is specified in bulk-mode\n"
        else
          v.run_bulk
        end
      else
        for file in ARGV do
          Juli::Parser.new.parse(file, v)
        end
      end
    end

  private
    def write_config(f, key, value)
      if value
        f.printf("%s: %s\n", key, value)
      end
    end

    # write each macro conf sample to initial .juli/conf file
    # by calling 'conf_template' method on each macro.
    def write_macro_conf(f)
      for macro_symbol in Juli::Macro.constants do
        next if macro_symbol == :Base
        macro_class = Juli::Macro.module_eval(macro_symbol.to_s)
        f.print "\n", macro_class.conf_template
      end
    end

    # write each helper conf sample to initial .juli/conf file
    # by calling 'conf_template' method on each macro.
    def write_helper_conf(f)
      for helper_symbol in Juli::Visitor::Html::Helper.constants do
        next if helper_symbol == :AbstractHelper
        helper_class = Juli::Visitor::Html::Helper.module_eval(helper_symbol.to_s)
        f.print "\n", helper_class.conf_template
      end
    end
  end
end

