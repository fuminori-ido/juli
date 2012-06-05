require 'pathname'
require 'singleton'
require 'yaml'
require 'juli'

module Juli
  module Util
    def camelize(str)
      str.gsub(/\/(.?)/) { "::#{$1.upcase}" }.gsub(/(?:^|_)(.)/) { $1.upcase }
    end

    # Visitor::#{str} constantize
    def visitor(str)
      camelized = camelize(str)
      if Visitor.const_defined?(camelized)
        Visitor.const_get(camelize(str))
      else
        raise "Visitor #{camelized} is not defined."
      end
    end
    module_function :visitor

    def visitor_list
      result = []
      sorted_visitors = Dir.glob(File.join(Juli::LIB, 'visitor/*.rb')).sort
      for f in sorted_visitors do
        next if f =~ /^\./
        result << File.basename(f).gsub(/\.rb$/, '')
      end
      result
    end
    module_function :visitor_list

    def usage
      <<EOM
USAGE: juli [general_options] COMMAND [command_options] [files]

general_options:
  --help
  --version

COMMAND (default = gen):
  init                initialize current directory as juli-repo
  gen                 generate outputs from files under juli-repo
                      This is the default juli command.
  sitemap             generate sitemap to JULI_REPO/sitemap.shtml
  recent_update       generate reent updates to JULI_REPO/recent_update.shtml

                      NOTE: file extention '.shtml' above is the default.
                      you can change it by 'init' command -e option
                      (see below), or by modifying JULI_REPO/.juli/config
                      'ext' entry later anytime.

  tag                 generate tag-list page.  see tag(macro) manual.

command_options for:
  init:
    -o output_top     default='../html/'
    -t template       set the template at config (default='default.html').
                      This template name will be used at 'gen' command
                      (described below) to search 1) JULI_REPO/.juli/ or
                      2) lib/juli/template/
    -e ext            generating html file extention (default='.shtml')

  gen:
    -g generator      specify generator as follows(default=html):
                         #{visitor_list.join("\n" + " "*25)}
    -f                force generate
    -t template_path  use the template path rather than juli-config value
                      set at 'juli init -t ...'
    -o output_path    specify output file path.  It cannot be set at bulk-mode.
                      default is under the directory defined at .juli/config
                      'output_top' entry.

Where, JULI_REPO is the directory which 'juli init' is executed.
EOM
    end
    module_function :usage

    def str_limit(str)
      str.size > 45 ? str[0..45] + '...' : str
    end
    module_function :str_limit

    # trim string just for printing purpose here
    def str_trim(str)
      str_limit(str.gsub(/\n/, '\n').gsub(/\r/, '\r'))
    end
    module_function :str_trim

    # Similar to Rails underscore() method.
    #
    # Example: 'A::B::HelperMethod' -> 'helper_method'
    def underscore(str)
      str.gsub(/.*::/,'').
          gsub(/([A-Z]+)([A-Z][a-z])/,'\1_\2').
          gsub(/([a-z\d])([A-Z])/,'\1_\2').
          tr("-", "_").
          downcase
    end
    module_function :underscore
    
    # find juli-repository root from the specified path.
    class Repo
      attr_reader :juli_repo 

      def initialize(path = '.')
        Pathname.new(path).realpath.ascend do |p|
          p_str = File.join(p, Juli::REPO)
          if File.directory?(p_str)
            @juli_repo = p
            return
          end
        end
        raise "cannot find juli repository root."
      end
    end

    # fullpath of juli-repository
    #
    # it is enough to have one value in whole juli modules so
    # SINGLETON-pattern is used.
    def juli_repo(path='.')
      $_repo ||= Repo.new(path)
      $_repo.juli_repo
    end
    module_function :juli_repo

    class Config
      include Singleton
      class Error < Exception; end
      attr_reader :conf

      def initialize
        @conf = YAML::load(ERB.new(File.read(
            File.join(Juli::Util::juli_repo, Juli::REPO, 'config'))).result)

        raise Error if !@conf
      end
    end

    # return REPO/config hash
    def conf
      Config.instance.conf
    end
    module_function :conf

    # mkdir for out_file if necessary
    def mkdir(path)
      dir = File.dirname(path)
      if !File.directory?(dir)
        FileUtils.mkdir_p(dir)
      end
    end
    module_function :mkdir

    # input filename to wikiname
    #
    # === INPUTS
    # in_filename:: juli repo file path
    #
    # === EXAMPLE
    # diary/2010/12/31.txt -> diary/2010/12/31
    def to_wikiname(in_filename)
      in_filename.gsub(/\.[^\.]*$/,'')
    end
    module_function :to_wikiname

    # === INPUTS
    # in_filename:: relative path under repository
    # o_opt::       output path which -o command-line option specifies
    #
    # === RETURN
    # full path of out filename.  if o_opt is specified,
    # it is used.
    #
    # === EXAMPLE
    # diary/2010/12/31.txt -> OUTPUT_TOP/diary/2010/12/31.shtml
    #
    def out_filename(in_filename, o_opt = nil)
      o_opt ||
          File.join(conf['output_top'],
                    to_wikiname(in_filename) + conf['ext'])
    end
    module_function :out_filename

    # === INPUTS
    # out_filename:: relative path under OUTPUT_TOP
    #
    # === RETURN
    # relative path of in-filename, but **no extention**.
    #
    # === EXAMPLE
    # diary/2010/12/31.shtml -> 31
    def in_filename(out_filename)
      File.join(File.dirname(out_filename),
                File.basename(out_filename).gsub(/\.[^\.]*$/,''))
    end
    module_function :in_filename

    # find erb template in the following order:
    #
    # if t_opt ('-t' command-line option arg) is specified:
    #   1st) template_path in absolute or relative from current dir, or
    #   2nd) -t template_path in JULI_REPO/.juli/, or
    #   3rd) -t template_path in lib/juli/template/
    #   otherwise, error
    # else:
    #   4th) {template} in JULI_REPO/.juli/, or
    #   5th) {template} in lib/juli/template.
    #   otherwise, error
    #
    # Where, {template} means conf['template']
    #
    # === INPUTS
    # template::  template name
    # t_opt::     template name which -t command-line option specifies
    def find_template(template, t_opt = nil)
      if t_opt
        if File.exist?(t_opt)
          t_opt
        else
          find_template_sub(t_opt)
        end
      else
        find_template_sub(template)
      end
    end
    module_function :find_template

  private
    # find template 't' in dirs
    def find_template_sub(t)
      for path in [File.join(juli_repo, Juli::REPO), Juli::TEMPLATE_PATH] do
        template = File.join(path, t)
        return template if File.exist?(template)
      end
      raise Errno::ENOENT, "no #{t} found"
    end
  end
end
