require 'test/unit'

$LOAD_PATH << File.join(File.dirname(__FILE__), '../lib')

class Test::Unit::TestCase
  # require lib/**/*.rb
  Dir.glob(File.join(File.dirname(__FILE__), '../lib/**/*.rb')){|f|
    require f
  }

  def repo4test
    File.join(File.dirname(__FILE__), 'repo')
  end
end