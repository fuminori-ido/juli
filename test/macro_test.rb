require 'fileutils'
require 'test_helper'
require 'juli/util'
require 'juli/macro'

include Juli::Util
include Juli::Macro

class MacroTest < Test::Unit::TestCase
  def setup
    @saved_cwd = Dir.pwd
    Dir.chdir(repo4test)
  end

  def teardown
    Dir.chdir(@saved_cwd)
  end

  def test_amazon_run
    assert_equal(
        '<span class="juli_macro_amazon">X</x>',
        Juli::Macro::Amazon.new.run('X'))
  end
end
