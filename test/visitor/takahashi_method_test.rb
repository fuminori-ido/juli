require 'test_helper'

class TakahashiMethodTest < Test::Unit::TestCase
  def setup
    @saved_cwd = Dir.pwd
    Dir.chdir(repo4test)
  end

  def teardown
    Dir.chdir(@saved_cwd)
  end

  def test_run_bulk
    assert_nothing_raised do
      Juli::Visitor::TakahashiMethod.new.run_bulk
    end
  end

  def test_run_file
    assert_nothing_raised do
      Juli::Parser.new.parse('t001.txt', Juli::Visitor::TakahashiMethod.new)
    end
  end
end
