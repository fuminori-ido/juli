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
      result.join(',')
    end
    module_function :visitor_list

    def usage
      <<EOM
USAGE: juli [general_options] COMMAND [command_options] [files]

general_options:
  --help
  --version

COMMAND (default = gen):
  init
  gen  
  sitemap             generate sitemap to $JULI_REPO/sitemap.shtml
  recent_update       generate reent updates to $JULI_REPO/recent_update.shtml

                      NOTE: file extention '.shtml' above is the default.
                      you can change it by 'init' command -e option
                      (see below), or by modifying $JULI_REPO/.juli/config
                      'ext' entry later anytime.

command_options for:
  init:
    -o output_top     default='../html/'
    -t template       use template at 1) $JULI_REPO/.juli/ or
                      2) lib/juli/template/ (default='default').
                      Search priority is 1), and then 2).
    -e ext            generating html file extention (default='.shtml')

  gen:
    -g generator      specify generator (#{visitor_list}) default=html
    -f                force generate
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
        @conf = YAML::load_file(
                    File.join(Juli::Util::juli_repo, Juli::REPO, 'config'))

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

    # === INPUTS
    # in_filename:: relative path under repository
    #
    # === RETURN
    # full path of out filename
    #
    # === EXAMPLE
    # diary/2010/12/31.txt -> OUTPUT_TOP/diary/2010/12/31.shtml
    #
    def out_filename(in_filename)
      File.join(conf['output_top'],
                in_filename.gsub(/\.[^\.]*$/,'') + conf['ext'])
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
  end
end
