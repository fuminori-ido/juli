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

    def test_run_config
      assert_equal(
        '<iframe src="http://map_test/-1,-2"></iframe>' +
        '<a href="http://map_test/-1,-2">Map</a>',
          @jmap.run('-1,-2'))
    end

    def test_run_default
      saved = conf['jmap']
        conf['jmap'] = nil
        assert_match /google.com\/maps\?q=loc:-1,-2/, @jmap.run('-1,-2')
      conf['jmap'] = saved
    end
  end
end
