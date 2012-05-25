require 'fileutils'
require 'test_helper'
require 'juli'
require 'juli/util'
require 'juli/macro'

include Juli::Util
include Juli::Macro

module Macro
  class AmazonTest < Test::Unit::TestCase
    def setup
      @saved_cwd = Dir.pwd
      Dir.chdir(repo4test)
      @amazon = Juli::Macro::Amazon.new
    end
  
    def teardown
      Dir.chdir(@saved_cwd)
    end

    # Even if no config on amazon, it should be ok on new() and on_root().
    def test_no_conf
      saved = conf['amazon']
        conf['amazon'] = nil
        assert p = Juli::Macro::Amazon.new
        assert_nothing_raised do
          p.on_root('t001.txt', nil)
        end
      conf['amazon'] = saved
    end
  end
end
