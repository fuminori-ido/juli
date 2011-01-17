require 'test_helper'

module Visitor
  class TreeTest < Test::Unit::TestCase
    def test_class_run
      assert_nothing_raised do
        Juli::Visitor::Tree.run
      end
    end
  end
end