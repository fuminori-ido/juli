# coding: UTF-8

require 'test_helper'
require 'juli/util/juli_i18n'

class UtilJuliI18nTest < Test::Unit::TestCase
  include Juli::Util

  def setup
    @opts = {}
    @saved_cwd = Dir.pwd
    Dir.chdir(repo4test)
    I18n.reload!
  end

  def teardown
    Dir.chdir(@saved_cwd)
  end

  # case: 'ja' in conf
  def test_init
    i = Juli::Util::JuliI18n.new(conf, juli_repo)
    assert_equal '最近の更新(in test .juli)', I18n.t(:recent_updates)
  end

  # case: no locale in conf
  def test_init_default_locale
    saved = conf['locale']
      conf['locale'] = :en
      i = Juli::Util::JuliI18n.new(conf, juli_repo)
      assert_equal 'Recent Update(in test .juli)', I18n.t(:recent_updates)
    conf['locale'] = saved
  end

  # case: no locale yml file
  def test_init_default_locale_file
    begin
      curr_locale       = conf['locale']
      yml_to_be_hidden  = File.join(
          juli_repo, Juli::REPO, "#{curr_locale}.yml")
      bkp_file = yml_to_be_hidden + ".bkp"
      FileUtils.mv(yml_to_be_hidden, bkp_file)
      i = Juli::Util::JuliI18n.new(conf, juli_repo)
      assert_equal '最近の更新', I18n.t(:recent_updates)
    ensure
      if File.exist?(bkp_file)
        FileUtils.mv(bkp_file, yml_to_be_hidden)
      end
    end
  end
end