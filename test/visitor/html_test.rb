require 'test_helper'

OUTPUT_TOP  = '/tmp'
PKG_ROOT    = File.join(File.dirname(__FILE__), '../..')

class Visitor::HtmlTest < Test::Unit::TestCase
  def test_class_run
    assert_nothing_raised do
      Visitor::Html.run
    end
  end
end