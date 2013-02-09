# coding: UTF-8

require 'test_helper'

class LineParserTest < Test::Unit::TestCase
  def test_parse
    tests = [
# expected                  text          wikinames
#--------------------------------------------------
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
# multiline
[['abc', 'W:test', "d\ne", 'W:te', 'f'], "abctestd\netef", %w(test te)],
# wikiname in HTML tag should be escaped
[['abc', '<img src="hello">', 'def'], 'abc<img src="hello">def', ['hello']],
# URL
[['abc ','U:http://def',' ghi'],  'abc http://def ghi',   %w(test)],
# URL https is also recognized
[['abc ','U:https://def',' ghi'], 'abc https://def ghi',  %w(test)],
# (URL) is parsed correctly
[['abc(','U:https://def',')ghi'], 'abc(https://def)ghi',  %w(test)],
# '...のURLが' is parsed correctly
[['abcの','U:https://def','がghi'], 'abcのhttps://defがghi',  %w(test)],
# cgi URL is parsed correctly
[['abc ','U:https://def?a=b&c=%20',' ghi'], 'abc https://def?a=b&c=%20 ghi',  %w(test)],
# URL with tilda(~) is parsed correctly
[['abc ','U:https://def/~a',' ghi'], 'abc https://def/~a ghi',  %w(test)],
# URL with hash(#) is parsed correctly
[['abc ','U:https://def/a#b',' ghi'], 'abc https://def/a#b ghi',  %w(test)],
# URL git:... is NOT recognized :-(
[['abc git:def ghi'],             'abc git:def ghi',      %w(test)],
# URL is high priority than wikiname
[['abc ','U:http://def',' ghi'],  'abc http://def ghi', %w(def)],
# not isolated URL token is not recognized as URL
[['abchttp://def ghi'],           'abchttp://def ghi', %w(test)],
[['abchttp://', 'W:def', ' ghi'], 'abchttp://def ghi', %w(def)],
# <a>...</a> is interpreted just string to escape wikiname in <a> contents
[['abc', '<a href="#x">test</a>', 'def'],
    'abc<a href="#x">test</a>def', ['test']],
# escape of escape.  NOTE: following Ruby single-quote string '\\\\{...'
# means '\\{...' in actual byte data.
[%w(abc \\{ ! W:test }def),       'abc\\\\{!test}def', %w(test)],
# explicit escape
[%w(abc test def),                'abc\{!test}def', %w(X)],
# beggining with URL
[['','U:http://abc', ' def'],     'http://abc def', %w(X)],
# macro
[%w(abc M:amazon:ISBN... def),    'abc\{amazon ISBN...}def', %w(X)],
]

    for t in tests do
      check_parse(t[0], t[1], t[2])
    end
  end

private
  def check_parse(expected, text, wikinames)
    assert_nothing_raised do
      v = Juli::LineAbsyn::DebugVisitor.new
      Juli::LineParser.new.parse(text, wikinames).accept(v)
      assert_equal expected, v.array
    end
  end
end