require 'fileutils'
require 'test_helper'
require 'juli'
require 'juli/util'
require 'juli/macro'

include Juli::Util
include Juli::Macro

module Macro
  class WikipediaTest < Test::Unit::TestCase
    def setup
      @saved_cwd = Dir.pwd
      Dir.chdir(repo4test)
      @wp = Juli::Macro::Wikipedia.new
    end
  
    def teardown
      Dir.chdir(@saved_cwd)
    end

    # Even if no config of wikipedia, it should be ok on new() and on_root().
    def test_no_conf
      saved = conf['wikipedia']
        conf['wikipedia'] = nil
        assert p = Juli::Macro::Wikipedia.new
        assert_nothing_raised do
          p.on_root('t001.txt', nil)
        end
      conf['wikipedia'] = saved
    end

    def test_conf_key
      assert_equal 'wikipedia', @wp.conf_key
    end

    def test_place_holder
      assert_equal 'wikipedia', @wp.place_holder
    end

    def test_run_config
      assert_equal(
        '<a href="http://ja.wikipedia.org/wiki/Pitaya">Pitaya</a>',
          @wp.run('Pitaya'))
    end

    def test_run_default
      saved = conf['wikipedia']
        conf['wikipedia'] = nil
        assert_equal(
        '<a href="http://en.wikipedia.org/wiki/Pitaya">Pitaya</a>',
          @wp.run('Pitaya'))
      conf['wikipedia'] = saved
    end
  end
end
