require 'test_helper'

class JuliTest < Test::Unit::TestCase
  def test_command
    check(true,   '--help')
    check(true,   '--version')
    check(false,  '-z')
  end

private
  def check(expected, option)
    assert_equal expected, run_command(option)
  end

  def run_command(option)
    system 'ruby', File.join(File.dirname(__FILE__), '../bin/juli'), option
  end

  # redirect STDOUT in this block
  def stdout_to_dev_null
    $stdout = File.open('/dev/null', 'w')
    yield
    $stdout = STDOUT
  end
end