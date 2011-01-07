require 'test_helper'

PKG_ROOT    = File.join(File.dirname(__FILE__), '../..')

class Visitor::HtmlTest < Test::Unit::TestCase
  def setup
    @saved_cwd = Dir.pwd
    Dir.chdir(repo4test)
  end

  def teardown
    Dir.chdir(@saved_cwd)
  end

  def test_class_run
    assert_nothing_raised do
      Visitor::Html.run
    end
  end
end