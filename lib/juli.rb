require 'pathname'

# namespace for all of Juli library elements
module Juli
  VERSION       = '1.13.00'

  # sentinel to search juli-repo.  Also it's a directory name to sotre config.
  REPO          = '.juli'
  LIB           = File.join(Pathname.new(File.dirname(__FILE__)).realpath, 'juli')
  TEMPLATE_PATH = File.join(LIB, 'template')

  class JuliError < StandardError; end
end