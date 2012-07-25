require 'fileutils'
require 'test_helper'
require 'juli/util'
require 'juli/command'

include Juli::Util
include Juli::Command

class CommandWithoutChdirTest < Test::Unit::TestCase
  def test_init_from_sh
    check_from_sh('init')
  end

  def test_help_from_sh
    check_from_sh('-h')
  end

  def test_version_from_sh
    check_from_sh('-v')
  end

private
  # test without .juli repo
  def check_from_sh(sh_command_opt)
    juli_command = File.join(Pathname.new(File.dirname(__FILE__)).realpath,
        '../bin/juli')
    test_dir = '/tmp/dir_for_juli_%d' % rand(100000000)
    FileUtils.mkdir(test_dir)
    begin
      Dir.chdir(test_dir) do
        assert system(juli_command, sh_command_opt)
      end
    ensure
      FileUtils.rm_rf(test_dir)
    end
  end
end