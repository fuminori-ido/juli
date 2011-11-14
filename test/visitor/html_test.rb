require 'test_helper'

  class HtmlTest < Test::Unit::TestCase
    def setup
      @saved_cwd = Dir.pwd
      Dir.chdir(repo4test)
    end
  
    def teardown
      Dir.chdir(@saved_cwd)
    end
  
    def test_run_bulk
      assert_nothing_raised do
        Juli::Visitor::Html.new.run_bulk
      end
    end

  def test_run_file
    assert_nothing_raised do
      Juli::Parser.new.parse('t001.txt', Juli::Visitor::Html.new)
    end
  end
  
    def test_html_helper_relative_from
      h = Juli::Visitor::Html.new
      assert_equal './juli.js',     h.relative_from('a.txt',      'juli.js')
      assert_equal '../juli.js',    h.relative_from('a/b.txt',    'juli.js')
      assert_equal '../../juli.js', h.relative_from('a/b/c.txt',  'juli.js')
    end
  
    def test_header_sequence
      h = Juli::Visitor::HeaderSequence.new
      assert '1',                 h.gen(1)
      assert '2',                 h.gen(1)
      assert '2.1',               h.gen(2)
      assert '2.2',               h.gen(2)
      assert '3',                 h.gen(1)
      assert '3.1',               h.gen(2)
      assert '3.1.1',             h.gen(3)
      assert '3.1.2',             h.gen(3)
      assert '4',                 h.gen(1)
    end
  end
