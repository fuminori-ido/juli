require 'test_helper'

class ParserTest < Test::Unit::TestCase
  def test_parse
    stdout_to_dev_null do
      for file in ['t001.txt', 't002.txt'] do
        assert_nothing_raised do
          Juli::Parser.new.parse(data_path(file), Visitor::Tree)
        end
      end
    end
  end

private
  # return full path of test data file.
  def data_path(filename)
    File.join(File.dirname(__FILE__), 'repo', filename)
  end

  # redirect STDOUT in this block
  def stdout_to_dev_null
    $stdout = File.open('/dev/null', 'w')
    yield
    $stdout = STDOUT
  end
end