require 'fileutils'
require 'test_helper'
require 'juli/util'
require 'juli/command'

include Juli::Util
include Juli::Command

# test on 'test/repo2' juli-repository which has empty .juli/config.
class UtilWithoutChdirTest < Test::Unit::TestCase
  def teardown
    # reset conf again for subsequent other tests in 'rake test'
    reset_conf
  end

  def test_output_top
    # test 'test/repo' directory's config
    Dir.chdir(repo4test) do
      assert_equal '../html_for_test', conf['output_top']
    end

    # test 'test/repo2' directory's config
    reset_conf
    Dir.chdir(repo2_path) do
      assert_equal '../html', conf['output_top']
    end
  end

  def test_default_conf_for_each_macro
    reset_conf
    Dir.chdir(repo2_path) do
      Juli::Visitor::Html.new   # register default for each macro
      assert_equal Juli::Macro::Jmap::DEFAULT_TEMPLATE, conf['jmap']
    end
  end

private
  def repo2_path
    File.join(Pathname.new(File.dirname(__FILE__)).realpath, 'repo2')
  end

  # clear global variables:
  # 1. clear Juli::Util::Config singleton instance.
  #    Since it keeps to live during 'rake test', it is required to
  #    re-initialize the config to test the case 'if no config exist' here
  #    in this unit-test.
  # 1. clear $_repo global variable.
  def reset_conf
    Juli::Util::Config.instance_variable_set('@singleton__instance__', nil)
    $_repo = nil
  end
end