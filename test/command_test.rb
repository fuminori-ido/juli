require 'fileutils'
require 'test_helper'
require 'juli/util'
require 'juli/command'

include Juli::Util
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
    clean_output
    assert_nothing_raised do
      Juli::Command.run('init', :g=>'html')
    end
    assert_nothing_raised do
      Juli::Command.run('init', :g=>'tree')
    end
  end

  def test_gen
    clean_output
    assert_nothing_raised do
      Juli::Command.run('gen', :g=>'html')
    end
    assert_nothing_raised do
      Juli::Command.run('gen', :g=>'tree')
    end
  end

private
  def repo4test
    @repo4test ||= Pathname.new(File.join(File.dirname(__FILE__),
                        'repo')).realpath.to_s
  end

  def clean_output
    FileUtils.rm_rf(conf['output_top'])
  end

  # delete whole test repo, rebuild & chdir to it, and run block.
  #
  # NOTE: when clear test repo(repo4test), current directory is disappeared.
  # This causes Errno::ENOENT on Dir.chdir(repo4test) *block* since
  # chdir with block requires current directory.  This is the reason why
  # chdir to @saved_cwd first, clear repo4test, and then chdir to repo4test.
  def reset_repo(&block)
    yield
=begin
    Dir.chdir(@saved_cwd){
      system 'rm', '-rf', repo4test
      if !File.directory?(repo4test)
        repo = File.join(repo4test, Juli::REPO)
        FileUtils.mkdir_p(repo)
        FileUtils.cp(File.join(repo4test, '../data/config'), repo,
            :preserve=>true)
      end
      Dir.chdir(repo4test){
        yield
      }
    }
=end
  end
end