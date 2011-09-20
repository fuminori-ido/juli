require 'test_helper'

class SlidyTest < Test::Unit::TestCase
  def setup
    @saved_cwd = Dir.pwd
    Dir.chdir(repo4test)
  end

  def teardown
    Dir.chdir(@saved_cwd)
  end

  def test_run_bulk
    assert_nothing_raised do
      Juli::Visitor::Slidy.new.run_bulk
    end
  end

  def test_run_file
    assert_nothing_raised do
      Juli::Parser.new.parse('t001.txt', Juli::Visitor::Slidy.new)
    end
  end
end
