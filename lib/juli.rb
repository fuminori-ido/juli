require 'i18n'
require 'pathname'
require "juli/version"

# namespace for all of Juli library elements
module Juli
  # sentinel to search juli-repo.  Also it's a directory name to sotre config.
  REPO          = '.juli'
  LIB           = File.join(Pathname.new(File.dirname(__FILE__)).realpath, 'juli')
  TEMPLATE_PATH = File.join(LIB, 'template')

  class JuliError       < StandardError; end
    class NoConfig        < JuliError; end
    class NotImplemented  < JuliError; end

  class << self
    def init
      I18n.enforce_available_locales = false
    end
  end
end
