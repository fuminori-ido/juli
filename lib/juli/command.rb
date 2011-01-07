require 'juli/util'
require 'juli/parser.tab'

include Juli::Util

module Juli
  # juli command execution
  module Command
    class Error < Exception; end

    # top level command execution.  command_str will be checked and
    # dispatched to each method.
    def run(command_str, opts = {})
      case command_str
      when 'init';  init(opts)
      when 'gen';   gen(opts)
      else
        STDERR.print "Unknown juli command: '#{command_str}'\n\n", usage, "\n"
        raise Error
      end
    end

    # init does:
    #
    # 1. create juli-repository at the current directory, if not yet.
    # 1. create config file under the juli-repo, if not yet.
    #    This stores juli-repo dependent information.
    # 1. if parameters are specified, store it in config file under juli-repo.
    #
    # === OPTIONS
    # -o output_top
    def init(opts)
      if !File.directory?(Juli::REPO)
        FileUtils.mkdir(Juli::REPO)
      else
        STDERR.print "WARN: juli-repo is already created\n"
      end

      config_file = File.join(Juli::REPO, 'config')
      if !File.exist?(config_file)
        File.open(config_file, 'w') do |f|
          if opts[:o]
            f.printf("output_top: %s\n", opts[:o])
          else
            f.printf("# TBD\n")
          end
        end
      else
        STDERR.print "WARN: config file is already created\n"
      end
    end

    # generate command
    #
    # === OPTIONS
    # -g generator
    def gen(opts)
      # executes each generator's init here:
      visitor(opts[:g]).init

      if ARGV.empty?
        print "bulk mode\n"
        visitor(opts[:g]).run
      else
        for file in ARGV do
          Juli::Parser.new.parse(file, visitor(opts[:g]))
        end
      end
    end
  end
end
