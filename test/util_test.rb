require 'test_helper'

include Juli::Util

class UtilTest < Test::Unit::TestCase
  def setup
    @saved_cwd = Dir.pwd
    Dir.chdir(repo4test)
  end

  def teardown
    Dir.chdir(@saved_cwd)
  end

  def test_camelize
    assert_equal 'HelloWorld', camelize('hello_world')
  end

  def test_visitor
    assert_equal Juli::Visitor::Html, visitor('html')
  end

  def test_visitor_list
    assert_not_equal [], visitor_list
  end

  def test_usage
    assert_not_nil usage
  end

  def test_juli_repo
    assert_not_nil juli_repo
  end

  def test_conf
    assert_not_nil  conf['output_top']
    assert_nil      conf['** NEVER DEFINED KEY! **']
  end
end