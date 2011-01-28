require 'juli/util'
require 'juli/parser.tab'

module Juli
  # This is a top level module for juli(1) command execution.
  # Each juli(1) command corresponds to each method here.
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
          f.print "# put juli-repo config here.\n\n"
          write_config(f, 'output_top', opts[:o])
          write_config(f, 'template',   opts[:t])
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
      o = opts.dup
      o.delete(:g)
      # executes each generator's init here:
      v = visitor(opts[:g]).new

      if ARGV.empty?
        print "bulk mode\n"
        v.run_bulk(o)
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
  end
end
