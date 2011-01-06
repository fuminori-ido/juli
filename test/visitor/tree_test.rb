require 'test_helper'

class Visitor::TreeTest < Test::Unit::TestCase
  def test_class_run
    assert_nothing_raised do
      Visitor::Tree.run
    end
  end
end