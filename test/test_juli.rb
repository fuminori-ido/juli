require 'minitest_helper'

class TestJuli < Minitest::Test
  def test_that_it_has_a_version_number
    refute_nil ::Juli::VERSION
  end

  def test_it_does_something_useful
    assert false
  end
end
