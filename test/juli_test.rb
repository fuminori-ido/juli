require 'test_helper'

class JuliTest < Test::Unit::TestCase
  def test_command
    Dir.chdir(repo4test) do
      check(true,   '--help')
      check(true,   '--version')
      check(false,  '-z')
      check(false,  '/etc/group')
    end
  end

  def test_find_template
    Dir.chdir(repo4test) do
      # default template should be in TEMPLATE_PATH
      assert_equal File.join(Juli::TEMPLATE_PATH, 'default.html'),
                   find_template(conf['template'])
  
      # when same name is in juli_repo, that should be chosen
      test_template = File.join(Juli::Util.juli_repo, Juli::REPO, 'default.html')
      FileUtils.cp(find_template(conf['template']), test_template)
      assert_equal test_template, find_template(conf['template'])
      # clean after the test above
      FileUtils.rm_f(test_template)
  
      # when no template in both path, error should be raised
      saved = conf['template']
        conf['template'] = '!!NEVER_MATCHED!!.html'
        assert_raise Errno::ENOENT do
          find_template(conf['template'])
        end
      conf['template'] = saved
  
      # check if option works
      assert_equal '/etc/passwd', find_template(nil, '/etc/passwd')
    end
  end

private
  def check(expected, *args)
    assert_equal expected, run_command(args), args
  end

  def run_command(*args)
    system *['ruby', File.join(File.dirname(__FILE__), '../bin/juli'), args].flatten
  end

  # redirect STDOUT in this block
  def stdout_to_dev_null
    $stdout = File.open('/dev/null', 'w')
    yield
    $stdout = STDOUT
  end
end
