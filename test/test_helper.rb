gem 'minitest', '4.7.5'
require 'minitest/autorun'
require 'test/unit'

$LOAD_PATH.insert(0,
    # be absolute path to avoid ../lib is ignored when chdir to 'repo'
    File.expand_path(File.join(File.dirname(__FILE__), '../lib')))

# require lib/**/*.rb
require 'juli'
require 'juli/command'
require 'juli/macro'
require 'juli/visitor'
require 'juli/wiki'

Juli.init

class Test::Unit::TestCase
  include Juli::Util

  def repo4test
    File.join(File.dirname(__FILE__), 'repo')
  end

  def repo2_4test
    File.join(Pathname.new(File.dirname(__FILE__)).realpath, 'repo2')
  end

  # reset juli-conf during the block
  def reset_conf(&block)
    reset_conf_sub
    yield

    # reset again to go back to default setting later.  Otherwise,
    # above setting is kept later.
    reset_conf_sub
  end

  # 1. clear Juli::Util::Config singleton instance.
  #    Since it keeps to live during 'rake test', it is required to
  #    re-initialize the config to test the case 'if no config exist' here
  #    in this unit-test.
  # 1. clear $_repo global variable.
  def reset_conf_sub
    Juli::Util::Config.instance_variable_set('@singleton__instance__', nil)
    $_repo = nil
  end
end