require 'fileutils'
require 'test_helper'

include Juli::Command

class CommandTest < Test::Unit::TestCase
  def setup
    @saved_cwd = Dir.pwd
    Dir.chdir(repo4test)
  end

  def teardown
    Dir.chdir(@saved_cwd)
  end

  def test_run
    assert_raise Juli::Command::Error do
      Juli::Command.run('else')
    end
  end

  def test_init
    clean_repo
    make_repo
  end

  def test_gen
    assert_nothing_raised do
      Juli::Command.run('gen', :g=>'html')
    end
  end

private
  def repo4test
    @repo4test ||= Pathname.new(
                        File.join(File.dirname(__FILE__), 'repo')).realpath
  end

  def make_repo
    if !File.directory?(repo4test)
      repo = File.join(repo4test, Juli::REPO)
      FileUtils.mkdir_p(repo)
      FileUtils.cp(File.join(repo4test, '../data/config'), repo,
          :preserve=>true)
    end
  end

  def clean_repo
    system 'rm', '-rf', repo4test
  end
end