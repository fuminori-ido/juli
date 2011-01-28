require 'test/unit'

$LOAD_PATH.insert(0,
    # be absolute path to avoid ../lib is ignored when chdir to 'repo'
    File.expand_path(File.join(File.dirname(__FILE__), '../lib')))

  # require lib/**/*.rb
  Dir.glob(File.join(File.dirname(__FILE__), '../lib/juli/*.rb')){|f|
    require f
  }

class Test::Unit::TestCase

  def repo4test
    File.join(File.dirname(__FILE__), 'repo')
  end
end