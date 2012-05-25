require 'fileutils'
require 'test_helper'
require 'juli'
require 'juli/util'
require 'juli/visitor'

include Juli::Util

# NOTE: Following module name cannot be Juli::Visitor::Html::Helper because
# if so, FbLikeTest would become a *WRONG HELPER* under
# Juli::Visitor::Html::Helper and failed at testing.
module JuliUnitTest
  class FbLikeTest < Test::Unit::TestCase
    def setup
      @saved_cwd = Dir.pwd
      Dir.chdir(repo4test)
      Dir.glob('.juli/*.gdbm'){|f| FileUtils.rm_f(f) }
      @fb_like = Juli::Visitor::Html::Helper::FbLike.new
    end
  
    def teardown
      Dir.chdir(@saved_cwd)
    end

    def test_new
      assert @fb_like
    end

    # Even if no config, it should be ok on new() and on_root().
    def test_no_conf
      saved0 = conf['url_prefix']; saved = conf['facebook']
        conf['url_prefix'] = conf['facebook'] = nil
        assert p = Juli::Visitor::Html::Helper::FbLike.new
        assert_nothing_raised do
          p.on_root('t001.txt', nil)
        end
      conf['facebook'] = saved
      conf['url_prefix'] = saved0
    end

    def test_template
      # template in .juli/config
      assert_equal '<fb:like href="%{href}"></fb:like>', @fb_like.send(:template)

      # default template
      saved = conf['facebook']['like']['template']
        conf['facebook']['like']['template'] = nil
        assert_match /width=/, @fb_like.send(:template)          #/
      conf['facebook']['like']['template'] = saved
    end

    def test_run
      @fb_like.on_root('a.txt', nil)
      assert_equal(
          '<fb:like href="http://local:PORT/JULI/a.html"></fb:like>',
          @fb_like.run)
    end
  end
end
