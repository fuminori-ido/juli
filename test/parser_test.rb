require 'test_helper'
require 'pp'

class ParserTest < Test::Unit::TestCase
  def setup
    #$stdout = File.open('/dev/null', 'w')

    # set juli_repo since parser referes it
    Juli::Util.juli_repo(File.join(File.dirname(__FILE__), 'repo'))
  end

  def teardown
    #$stdout = STDOUT
  end

  def test_nest_stack
    is = Juli::Parser::NestStack.new
    is.push(2);   assert_equal 2, is.baseline
    is.push(4);   assert_equal 4, is.baseline
    is.push(6);   assert_equal 6, is.baseline
    is.pop(4);    assert_equal 4, is.baseline
    is.push(6);   assert_equal 6, is.baseline
    is.pop(2);    assert_equal 2, is.baseline
    assert_raise(Juli::Parser::NestStack::InvalidOrder) do
      is.push(2)
    end

    # test flush
    is.push(4); is.push(6)
    count = 0
    is.flush{ count += 1 }
    assert_equal 3, count       # flushed stack depth
  end

  def test_string_blocks_only
    t = build_tree_on('t002.txt')
    assert_equal 5, t.array.size
  end

  def test_simple_headline
    t = build_tree_on('t003.txt')
    assert_equal 1, t.array.size
    assert_equal 1, t.array[0].array.size
  end

  def test_simple_ordered_list
    t = build_tree_on('t004.txt')
    assert_equal 1, t.array.size
    assert_equal 2, t.array[0].array.size
  end

  def test_simple_unordered_list
    t = build_tree_on('t006.txt')
    assert_equal 1, t.array.size
    assert_equal 2, t.array[0].array.size
  end

  def test_ordered_n_unordered_list
    t = build_tree_on('t007.txt')
    assert_equal 3, t.array.size
    assert_equal 2, t.array[0].array.size
  end

  def test_verbatim
    t = build_tree_on('t010.txt')
    assert_equal 4, t.array.size
  end

  def test_continued_list
    t = build_tree_on('t011.txt')
    assert_equal 3, t.array.size
    assert_equal 2, t.array[1].array.size
    assert_equal 2, t.array[2].array.size
  end

  def test_list_n_verbatim
    t = build_tree_on('t012.txt')
    assert_equal 10, t.array.size
    assert_equal  4, t.array[3].array.size
  end

  # t012-2.txt resulted in 'syntax error' at the git version
  # 0bc176893f57a6fdbecd0340101bd84a5eb724e0 (In other words, t012-2.txt was
  # the minimum input text to detect the parser bug of the version).
  def test_list_n_verbatim2
    t = build_tree_on('t012-2.txt')
    assert_equal  3, t.array.size
  end

  def test_list_n_verbatim3
    t = build_tree_on('t012-3.txt')
    assert_equal  2, t.array.size
    assert_equal  2, t.array[0].array.size
  end

  def test_continued_list3
    t = build_tree_on('t013.txt')
    assert_equal 2, t.array.size
  end

  def test_str_after_list
    t = build_tree_on('t014.txt')
    assert_equal 3, t.array.size
    assert_equal 2, t.array[1].array.size
  end

  def test_str_after_list2
    t = build_tree_on('t015.txt')
    assert_equal 2, t.array.size
    assert_equal 2, t.array[0].array.size
  end

  def test_str_after_list_with_quote
    t = build_tree_on('t016.txt')
    assert_equal 3, t.array.size
    assert_equal 2, t.array[1].array.size
  end

  def test_continued_list5
    t = build_tree_on('t017.txt')
    assert_equal 6, t.array.size
  end

  def test_nested_chapter
    t = build_tree_on('t018.txt')
    assert_equal 1, t.array.size              # number of blocks
    assert_equal 1, t.array[0].array.size     # number of chapters
                                              # number of blocks in chapter1
    assert_equal 2, t.array[0].array[0].blocks.array.size
  end

  def test_whiteline
    t = build_tree_on('t019.txt')
    assert_equal 2, t.array.size              # number of blocks
  end

  def test_nested_header_and_paragraph
    t = build_tree_on('t020.txt')
    assert_equal 1, t.array.size              # number of top blocks
    assert_equal 1, t.array[0].array.size     # number of chapters
                                              # number of blocks in chapter1
    assert_equal 5, t.array[0].array[0].blocks.array.size
  end

  def test_quote_in_list
    t = build_tree_on('t021.txt')
    assert_equal 1, t.array.size              # number of blocks
    assert_equal 2, t.array[0].array.size     # number of list items
                                              # number of elements@1st list item
    assert_equal 3, t.array[0].array[0].array.size
  end

  def test_nested_quote
    t = build_tree_on('t022.txt')
  end

  def test_nested_quote2
    t = build_tree_on('t022-2.txt')
    assert_equal 3, t.array.size
    assert_equal 1, t.array[2].array.size
  end

  # This is a kind of irregular case, but Juli must parse as much as
  # possible.  So far, it should be 2 verbatims and one list.
  def test_nested_quote3
    t = build_tree_on('t022-3.txt')
    assert_equal 3, t.array.size
    assert_equal 1, t.array[2].array.size
  end

  def test_quote_after_list
    t = build_tree_on('t023.txt')
    # 5 elements(text, list, text, quote, text) at top level:
    assert_equal 5, t.array.size
  end

  def test_header_quote_without_list
    t = build_tree_on('t024.txt')
    assert_equal 2, t.array.size
    assert_equal 1, t.array[1].array.size
    assert_equal Juli::Absyn::Verbatim,
        t.array[1].array[0].blocks.array[0].array[0].blocks.array[0].class
  end

  def test_compact_dictionary_list
    t = build_tree_on('t027.txt')
    assert_equal 2, t.array.size
    assert_equal Juli::Absyn::CompactDictionaryList,
                 t.array[0].class
    assert_equal 2, t.array[0].array.size
  end

  def test_dictionary_list
    t = build_tree_on('t028.txt')
    assert_equal 2, t.array.size
    assert_equal Juli::Absyn::DictionaryList,
                 t.array[0].class
    assert_equal 3, t.array[0].array.size
  end

=begin
  # even if list order is incorrect, parser shouldn't failed and
  # it is recognized as top-level.
  def test_nested_ordered_list_incorrect
    assert_nothing_raised do
      parser = Juli::Parser.new
      parser.parse(data_path('t005.txt'), Juli::Visitor::Tree.new)
    end
  end

  def test_line_break
    t = build_tree_on('t008.txt')

    # [s o o o o q h]
    #
    # Where, s = str, o = ordered list, q = quote, h = header
    assert_equal 8, t.array.size
    assert_equal Juli::Absyn::StrNode,     t.array[6].class
    assert_equal Juli::Absyn::HeaderNode,  t.array[7].class
  end

  def test_quote_or_nested_list
    t = build_tree_on('t009.txt')
    assert_equal 4, t.array.size
    assert_equal 2, t.array[1].array.size
  end

  # nested quote (e.g. source program) should be in 1 quote.
  def test_quote_with_several_nest_level
    t = build_tree_on('t022.txt')
    # 6 elements(text, quote, text, quote, list, text) at top level:
    assert_equal 6, t.array.size

    # 3rd element is quote and next is list:
    assert_equal Juli::Absyn::StrNode,     t.array[3].class
    assert_equal Juli::Absyn::OrderedList, t.array[4].class
  end
=end

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

  def build_tree_on(test_file)
    parser = Juli::Parser.new
    parser.parse(data_path(test_file), Juli::Visitor::Tree.new)
    parser.tree
  end
end