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
  gen  

command_options for:
  gen:
    -g generator
EOM
    end
  end
end
