require 'fileutils'
require 'test_helper'
require 'juli'
require 'juli/util'
require 'juli/macro'

include Juli::Util
include Juli::Macro

module Macro
  class JmapTest < Test::Unit::TestCase
    def setup
      @saved_cwd = Dir.pwd
      Dir.chdir(repo4test)
      @jmap = Juli::Macro::Jmap.new
    end
  
    def teardown
      Dir.chdir(@saved_cwd)
    end

    # Even if no config on jmap, it should be ok on new() and on_root().
    def test_no_conf
      saved = conf['jmap']
        conf['jmap'] = nil
        assert p = Juli::Macro::Photo.new
        assert_nothing_raised do
          p.on_root('t001.txt', nil)
        end
      conf['jmap'] = saved
    end

    def test_run_config
      assert_equal(
        '<iframe src="http://map_test/-1,-2"></iframe>' +
        '<a href="http://map_test/-1,-2">Map</a>',
          @jmap.run('-1,-2'))
    end
  end
end
