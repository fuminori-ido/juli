require 'test_helper'

class LineParserTest < Test::Unit::TestCase
  def test_parse
    tests = [
# simplest
[['abc', 'W:test', 'def'], 'abctestdef', ['test']],
# empty wikinames
[['abctestdef'],           'abctestdef', []],
# no match
[['abctestdef'],           'abctestdef', ['hello']],
# two matches
[%w(abc W:te st W:de f),   'abctestdef', %w(te de)],
# longest match has higher priority
[%w(abc W:test def),       'abctestdef', %w(test te)],
# longest match has higher priority(2)
[%w(abc W:test de W:te f), 'abctestdetef', %w(test te)],
]

    for t in tests do
      check_parse(t[0], t[1], t[2])
    end
  end

private
  def check_parse(expected, text, wikinames)
    assert_nothing_raised do
      v = LineAbsyn::DebugVisitor.new
      Juli::LineParser.new.parse(text, wikinames).accept(v)
      assert_equal expected, v.array
    end
  end
end