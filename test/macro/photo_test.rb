require 'fileutils'
require 'test_helper'
require 'juli'
require 'juli/util'
require 'juli/macro'

include Juli::Util
include Juli::Macro

module Macro
  class PhotoTest < Test::Unit::TestCase
    def setup
      @saved_cwd = Dir.pwd
      Dir.chdir(repo4test)
      @photo = Juli::Macro::Photo.new
      @photo.set_conf_default(conf)
    end
  
    def teardown
      Dir.chdir(@saved_cwd)
    end

    def test_new
      assert_equal(
          File.realpath(File.join(repo4test, '../protected_photo')),
          @photo.mount)
    end

    # Even if no config on photo, it should be ok on new() and on_root().
    def test_no_conf
      saved = conf['photo']
        conf['photo'] = nil
        assert p = Juli::Macro::Photo.new
        assert_nothing_raised do
          p.on_root('t001.txt', nil)
        end
      conf['photo'] = saved
    end

    def test_public_photo_dir
      dir = File.join(conf['output_top'], 'public_photo')
      FileUtils.rm_rf(dir)

      @photo.public_photo_dir
      assert File.directory?(dir), dir

      # call again, no problem
      @photo.public_photo_dir
      assert File.directory?(dir), dir
    end

    def test_photo_name
      assert_equal 'a_b_c_small.jpg', @photo.photo_name('a/b/c.jpg', :small)
    end

    def test_photo_path
      assert_equal(
          File.join('public_photo', '2012-04-17_01_small.jpg'),
          @photo.photo_path('2012-04-17/01.jpg', :small))
    end

    def test_intern
      p_dir = @photo.public_photo_dir(false)
      FileUtils.rm_rf(p_dir)

      p_path = @photo.photo_path('2012-04-17/01.jpg', :small, false)
      assert !File.exist?(p_path)

      @photo.intern('2012-04-17/01.jpg')
      assert File.exist?(p_path)

      # call again
      @photo.intern('2012-04-17/01.jpg')
      assert File.exist?(p_path)
    end

    def test_run
      assert_equal(
          "<a href=\"public_photo/2012-04-17_01_large.jpg\">" +
            "<img class=\"juli_photo_small\"" +
            " src=\"public_photo/2012-04-17_01_small.jpg\"" +
            " style=\"float: right\"" +
            " />" +
          "</a>",
          @photo.run('2012-04-17/01.jpg'))
    end
  end
end
