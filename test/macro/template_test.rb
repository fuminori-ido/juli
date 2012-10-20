# coding: UTF-8

require 'fileutils'
require 'test_helper'
require 'juli'
require 'juli/util'
require 'juli/macro'

include Juli::Util
include Juli::Macro

module Macro
  class TemplateTest < Test::Unit::TestCase
    def setup
      @saved_cwd = Dir.pwd
      Dir.chdir(repo4test)
    end
  
    def teardown
      Dir.chdir(@saved_cwd)
    end

    def test_run
      # Html visitor's @template is nil at first.
      v = Juli::Visitor::Html.new
      assert_nil v.instance_variable_get('@template')

      # simulate \{template takahashi_method.html}
      template_macro = Juli::Macro::Template.new
      template_macro.on_root(nil, nil, v)
      template_macro.run('takahashi_method.html')

      # after the macro execution, Html visitor's @template is set.
      assert_equal(
          'takahashi_method.html',
          v.instance_variable_get('@template'))
    end

  private
    def check_no_tag
    end
  end
end
