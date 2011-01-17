require 'pathname'

module Juli
  # sentinel to search juli-repo.  Also it's a directory name to sotre config.
  REPO          = '.juli'
  PKG_ROOT      = File.join(Pathname.new(File.dirname(__FILE__)).realpath, '..')
  TEMPLATE_PATH = File.join(PKG_ROOT, 'lib/juli/template')
end