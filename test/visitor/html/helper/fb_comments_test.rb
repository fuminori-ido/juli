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
      Dir.glob('.juli/*.sdbm*'){|f| FileUtils.rm_f(f) }
      @fb_comments = Juli::Visitor::Html::Helper::FbComments.new
      @fb_comments.set_conf_default(conf)
    end
  
    def teardown
      Dir.chdir(@saved_cwd)
    end

    def test_new
      assert @fb_comments
    end

    # Even if no config, it should be ok on new() and on_root().
    def test_no_conf
      saved0 = conf['url_prefix']; saved = conf['facebook']
        conf['url_prefix'] = conf['facebook'] = nil
        assert p = Juli::Visitor::Html::Helper::FbComments.new
        assert_nothing_raised do
          p.on_root('t001.txt', nil)
        end
      conf['facebook'] = saved
      conf['url_prefix'] = saved0
    end

    def test_template
      # template in .juli/config
      assert_equal(
          '<fb:comments href="%{href}"></fb:comments>',
          conf['facebook']['comments']['template'])

      # default template
      reset_conf do
        Dir.chdir(repo2_4test) do
          f = Juli::Visitor::Html::Helper::FbComments.new
          f.set_conf_default(conf)

          assert_equal(
              Juli::Visitor::Html::Helper::FbComments::DEFAULT_TEMPLATE,
              conf['facebook']['comments']['template'])
        end
      end
    end

    def test_run
      @fb_comments.on_root('a.txt', nil)
      assert_equal(
          '<fb:comments href="http://local:PORT/JULI/a.html"></fb:comments>',
          @fb_comments.run)
    end
  end
end
