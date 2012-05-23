require 'fileutils'
require 'test_helper'
require 'juli'
require 'juli/util'
require 'juli/visitor'

include Juli::Util

# NOTE: Following module name cannot be Juli::Visitor::Html::Helper because
# if so, FbCommentsTest would become a *WRONG HELPER* under
# Juli::Visitor::Html::Helper and failed at testing.
module JuliUnitTest
  class FbCommentsTest < Test::Unit::TestCase
    def setup
      @saved_cwd = Dir.pwd
      Dir.chdir(repo4test)
      Dir.glob('.juli/*.gdbm'){|f| FileUtils.rm_f(f) }
      @fb_comments = Juli::Visitor::Html::Helper::FbComments.new
    end
  
    def teardown
      Dir.chdir(@saved_cwd)
    end

    def test_new
      assert @fb_comments
    end

    def test_template
      # template in .juli/config
      assert_equal '<fb:comments href="%{href}"></fb:comments>', @fb_comments.send(:template)

      # default template
      saved = conf['facebook']['comments']['template']
        conf['facebook']['comments']['template'] = nil
        assert_match /width=/, @fb_comments.send(:template)          #/
      conf['facebook']['comments']['template'] = saved
    end

    def test_run
      @fb_comments.on_root('a.txt', nil)
      assert_equal(
          '<fb:comments href="http://local:PORT/JULI/a.html"></fb:comments>',
          @fb_comments.run)
    end
  end
end
