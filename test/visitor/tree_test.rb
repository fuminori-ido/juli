require 'test_helper'

  class TreeTest < Test::Unit::TestCase
    def test_run_bulk
      assert_nothing_raised do
        Juli::Visitor::Tree.new.run_bulk
      end
    end
  end
