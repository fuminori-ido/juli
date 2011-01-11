require 'test_helper'

class LineParserTest < Test::Unit::TestCase
  def test_parse
    assert_nothing_raised do
      Juli::LineParser.new.parse('abc')
    end
  end
end