require 'juli/util'
require 'juli/parser.tab'

include Juli::Util

module Juli
  # juli command execution
  module Command
    # top level command execution.  command_str will be checked and
    # dispatched to each method.
    def run(command_str, opts)
      case command_str
      when 'gen'
        gen(opts)
      else
        STDERR.print "Unknown juli command: '#{command_str}'\n\n", usage, "\n"
        exit 1
      end
    end

    # generate command
    #
    # === OPTIONS
    # -g generator
    def gen(opts)
      if ARGV.empty?
        print "bulk mode\n"
        visitor(opts[:g]).run
      else
        for file in ARGV do
          Juli::Parser.new.parse(file, visitor(OPTS[:g]))
        end
      end
    end
  end
end
