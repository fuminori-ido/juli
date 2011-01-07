require 'test_helper'

class JuliTest < Test::Unit::TestCase
  def test_command
    check(true,   '--help')
    check(true,   '--version')
    check(false,  '-z')
    check(false,  '/etc/group')
  end

private
  def check(expected, *args)
    assert_equal expected, run_command(args)
  end

  def run_command(*args)
    system *['ruby', File.join(File.dirname(__FILE__), '../bin/juli'), args].flatten
  end

  # redirect STDOUT in this block
  def stdout_to_dev_null
    $stdout = File.open('/dev/null', 'w')
    yield
    $stdout = STDOUT
  end
end