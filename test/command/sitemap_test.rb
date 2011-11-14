require 'fileutils'
require 'test_helper'
require 'juli/util'
require 'juli/command'

include Juli::Util
include Juli::Command

module Command
  class SitemapTest < Test::Unit::TestCase
    def setup
      @saved_cwd = Dir.pwd
      Dir.chdir(repo4test)
    end

    def teardown
      Dir.chdir(@saved_cwd)
    end

    def test_run
      FileUtils.rm_f(File.join(conf['output_top'], 'sitemap.html'))
      FileUtils.rm_f(File.join(conf['output_top'], 'sitemap_order_by_mtime_DESC.html'))
      assert_nothing_raised do
        Juli::Command::Sitemap.new.run({})
        assert File.exist?(File.join(conf['output_top'], 'sitemap.html'))
        assert File.exist?(File.join(conf['output_top'], 'sitemap_order_by_mtime_DESC.html'))
      end
    end
  end
end
