require 'test_helper'

module Command
  class RecentUpdateTest < Test::Unit::TestCase
    def setup
      @saved_cwd = Dir.pwd
      Dir.chdir(repo4test)
    end

    def teardown
      Dir.chdir(@saved_cwd)
    end

    def test_run
      FileUtils.rm_f(File.join(conf['output_top'], 'recent_update.shtml'))
      assert_nothing_raised do
        Juli::Command::RecentUpdate.new.run({})
        assert File.exist?(File.join(conf['output_top'], 'recent_update.shtml'))
      end
    end
  end
end
