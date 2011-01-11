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

    def usage
      <<EOM
USAGE: juli [general_options] COMMAND [command_options] [files]

general_options:
  --help
  --version

COMMAND (default = gen):
  init
  gen  

command_options for:
  init:
    -o output_top
  gen:
    -g generator      specify generator
    -f                force generate
EOM
    end

    def str_limit(str)
      str.size > 30 ? str[0..30] + '...' : str
    end

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

    class Config
      include Singleton
      class Error < Exception; end
      attr_reader :conf

      def initialize
        @conf = YAML::load_file(File.join(juli_repo, Juli::REPO, 'config'))

        raise Error if !@conf
      end
    end

    # return REPO/config hash
    def conf
      Config.instance.conf
    end
  end
end
