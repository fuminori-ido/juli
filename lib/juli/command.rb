require 'juli/util'
require 'juli/parser.tab'

include Juli::Util

module Juli
  module Command
    def run(command_str, opts)
      case command_str
      when 'gen'
        gen(opts)
      end
    end

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
