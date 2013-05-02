# coding: UTF-8

require 'fileutils'
require 'test_helper'
require 'juli'
require 'juli/util'
require 'juli/macro'

include Juli::Util
include Juli::Macro

module Macro
  class TagTest < Test::Unit::TestCase
    def setup
      @saved_cwd = Dir.pwd
      Dir.chdir(repo4test)
      Dir.glob('.juli/*.gdbm'){|f| FileUtils.rm_f(f) }
      @tag = Juli::Macro::Tag.new
    end
  
    def teardown
      Dir.chdir(@saved_cwd)
    end

    # rvm ruby-1.9.2-p318 fails this.  I have already reported this issue
    # to rvm team.  Ruby built from ruby-lang.org works expectedly.
    def test_gdbm
      key = 'あいうえおかきくけこ'
      val = 'たちつてとなにぬねの'
      @tag.tag_db[key] = val
      assert_equal val, @tag.tag_db[key].force_encoding(Encoding::UTF_8)
    end

    def test_new
      assert @tag
    end

    # Even if no config, it should be ok on new() and on_root().
    def test_no_conf
      #saved = conf['photo']
        #conf['photo'] = nil
        assert p = Juli::Macro::Tag.new
        assert_nothing_raised do
          p.on_root('t001.txt', nil)
        end
      #conf['photo'] = saved
    end

    def test_on_root
      @tag.page_db['t001'] = ''
      assert_equal      '', @tag.page_db['t001']
      @tag.on_root('t001.txt', nil)
      assert_not_equal  '', @tag.page_db['t001']
    end

    def test_run
      key = sprintf("%s%s%s", 't001', Juli::Macro::Tag::SEPARATOR, 'DIY')
      @tag.on_root('t001.txt', nil)
      @tag.tag_db['DIY']    = ''
      @tag.tag_page_db[key] = ''
      assert_equal '', @tag.run('DIY')
      assert_not_equal  '', @tag.tag_db['DIY']
      assert_not_equal  '', @tag.tag_page_db[key]
    end

    def test_pages
      @tag.on_root('t001.txt', nil)
      @tag.run('DIY', 'DOG')

      @tag.on_root('t002.txt', nil)
      @tag.run('DIY', 'CAT')

      assert_equal ['t001', 't002'],  @tag.pages('DIY').sort
      assert_equal ['t001'],          @tag.pages('DOG').sort
      assert_equal ['t002'],          @tag.pages('CAT').sort
    end

    # simulate 'no_tag' case on t002.txt
    def test_no_tag
      @tag.on_root('t002.txt', nil)
      @tag.after_root('t002.txt', nil)
      assert_equal '1', @tag.tag_page_db['t002_, __no_tag_']
    end

    # simulate to set tag after 'no_tag' case on t002.txt
    def test_no_tag_then_tag_set
      @tag.on_root('t002.txt', nil)
      @tag.after_root('t002.txt', nil)

      @tag.on_root('t002.txt', nil)
      @tag.run('CAR')
      @tag.after_root('t002.txt', nil)
      assert_nil        @tag.tag_page_db['t002_, __no_tag_']
      assert_equal '1', @tag.tag_page_db['t002_, _CAR']
    end

    # test delete_page
    def test_delete_tag
      @tag.page_db['t001'] = '1'
      assert_equal 1, @tag.page_db.keys.count

      @tag.delete_page('t001.txt')
      assert_equal 0, @tag.page_db.keys.count
    end

  private
    def check_no_tag
    end
  end
end
