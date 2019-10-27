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

    # = AWS
    # tests only when 'juli-test' profile exists
    def test_aws
      if !check_if_juli_test_profile_exists
        printf("no 'juli-test' AWS credentials profile -> skip aws-related test")
        return
      end

      saved = conf['photo']
        conf['photo']['storages'] = [
          'kind'      => 'aws',
          'params'    => {
            'region'  => 'ap-northeast-1',
            'profile' => 'juli-test',
          },
          'bucket'    => 'fumi-juli-test',
          'prefix'    => '',
        ]

        @photo = Juli::Macro::Photo.new

        p_dir = @photo.public_photo_dir(false)
        FileUtils.rm_rf(p_dir)

        p_path = @photo.photo_path('2019-10-26/green-monster.jpg', :small, false)
        assert !File.exist?(p_path)

        @photo.intern('2019-10-26/green-monster.jpg')
        assert File.exist?(p_path)

        # call again
        @photo.intern('2019-10-26/green-monster.jpg')
        assert File.exist?(p_path)

      conf['photo'] = saved
    end

    def check_if_juli_test_profile_exists
      if @juli_test_profile_exists.nil?
        path = ENV['HOME'] + '/.aws/credentials'
        @juli_test_profile_exists = File.exists?(path) &&
                                    system('grep', '^\[juli-test\]', path)
      else
        @juli_test_profile_exists
      end
    end
  end
end
