require 'test_helper'


class UtilTest < Test::Unit::TestCase
  include Juli::Util

  def setup
    @opts = {}
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

  def test_out_filename
    tests = [
      # expected            in-file
      ['hello.html',        'a/b/hello.txt'],
      ['Ubuntu 10.html',    'a/b/Ubuntu 10.txt'],
      ['Ubuntu 10.04.html', 'a/b/Ubuntu 10.04.txt'],
    ]

    for t in tests do
      assert_equal t[0], File.basename(out_filename(t[1]))
    end

    # if -o is specified, it should be used rather than wikiname
    @opts[:o] = 'special.html'
    assert_equal 'special.html', File.basename(out_filename('a/b/hello.txt'))
  end

  def test_in_filename
    tests = [
      # expected        out-file
      ['hello',         'a/b/hello.html'],
      ['Ubuntu 10',     'a/b/Ubuntu 10.html'],
      ['Ubuntu 10.04',  'a/b/Ubuntu 10.04.html'],
    ]

    for t in tests do
      assert_equal t[0], File.basename(in_filename(t[1]))
    end
  end
end