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
    assert_equal 3, t.array[0].array.size
  end

  def test_simple_unordered_list
    t = build_tree_on('t006.txt')
    assert_equal 1, t.array.size
    assert_equal 3, t.array[0].array.size
  end

  def test_ordered_n_unordered_list
    t = build_tree_on('t007.txt')
    assert_equal 3, t.array.size
    assert_equal 3, t.array[0].array.size
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
    assert_equal  6, t.array[3].array.size
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
    assert_equal 3, t.array[1].array.size
  end

  def test_nested_chapter
    t = build_tree_on('t018.txt')
    assert_equal 1, t.array.size              # number of blocks
    assert_equal 1, t.array[0].array.size     # number of chapters
                                              # number of blocks in chapter1
    assert_equal 2, t.array[0].array[0].blocks.array.size
  end

=begin
  def test_parse
    stdout_to_dev_null do
      for file in ['t001.txt', 't002.txt'] do
        assert_nothing_raised do
          Juli::Parser.new.parse(data_path(file), Juli::Visitor::Tree.new)
        end
      end
    end
  end

  def test_nested_ordered_list
    t = build_tree_on('t004.txt')
    assert_equal 1, t.array.size
    assert_equal Juli::Intermediate::OrderedList,     t.array[0].class
    assert_equal Juli::Intermediate::OrderedListItem, t.array[0].array[0].class
    assert_equal Juli::Intermediate::OrderedList,     t.array[0].array[1].class
  end

  # even if list order is incorrect, parser shouldn't failed and
  # it is recognized as top-level.
  def test_nested_ordered_list_incorrect
    assert_nothing_raised do
      parser = Juli::Parser.new
      parser.parse(data_path('t005.txt'), Juli::Visitor::Tree.new)
    end
  end

  def test_nested_unordered_list
    t = build_tree_on('t006.txt')
    assert_equal 1, t.array.size
    assert_equal Juli::Intermediate::UnorderedList,     t.array[0].class
    assert_equal Juli::Intermediate::UnorderedListItem, t.array[0].array[0].class
    assert_equal Juli::Intermediate::UnorderedList,     t.array[0].array[1].class
  end

  def test_nested_mixed_list
    t = build_tree_on('t007.txt')

    # [order-list, default, unorder-list]
    assert_equal 3, t.array.size
    assert_equal Juli::Intermediate::OrderedList,   t.array[0].class
    assert_equal Juli::Intermediate::UnorderedList, t.array[2].class

    # [order-item, unorder-list, order-item]
    assert_equal 3, t.array[0].array.size

    # [unorder-item, order-list, unorder-item]
    assert_equal 3, t.array[2].array.size
  end

  def test_line_break
    t = build_tree_on('t008.txt')

    # [s o o o o q h]
    #
    # Where, s = str, o = ordered list, q = quote, h = header
    assert_equal 8, t.array.size
    assert_equal Juli::Intermediate::StrNode,     t.array[6].class
    assert_equal Juli::Intermediate::HeaderNode,  t.array[7].class
  end

  def test_quote_or_nested_list
    t = build_tree_on('t009.txt')
    assert_equal 4, t.array.size
    assert_equal 2, t.array[1].array.size
  end

  def test_quote_in_list
    t = build_tree_on('t016.txt')
    assert_equal 3, t.array.size
    assert_match /a.*b.*c/m, t.array[1].array[0].array[1].str
  end

  def test_quote_and_normal
    t = build_tree_on('t010.txt')
    assert_equal 4, t.array.size
    assert_equal Juli::Intermediate::StrNode, t.array[2].class
    assert_equal Juli::Intermediate::StrNode,   t.array[3].class
  end

  def test_continued_list
    t = build_tree_on('t011.txt')
    assert_equal 3, t.array.size
    assert_equal 2, t.array[1].array.size
    assert_match /hello/, t.array[1].array[0].array[0].str
    assert_match /world/, t.array[1].array[0].array[0].str
    assert_equal 2, t.array[2].array.size
    assert_equal Juli::Intermediate::UnorderedList,     t.array[1].class
    assert_equal Juli::Intermediate::UnorderedListItem, t.array[1].array[1].class
  end

  def test_continued_list2
    t = build_tree_on('t012.txt')
    assert_match /b/, t.array[3].array[0].array[0].str
    assert_match /B/, t.array[3].array[0].array[0].str
  end

  def test_continued_list3
    t = build_tree_on('t013.txt')
    assert_equal Juli::Intermediate::UnorderedList, t.array[1].array[1].class
    assert_equal Juli::Intermediate::UnorderedListItem, t.array[1].array[2].class
  end

  def test_continued_list4
    t = build_tree_on('t014.txt')
    assert_equal 3, t.array.size
    assert_equal 2, t.array[1].array.size
  end

  def test_line_break_with_same_baseline
    t = build_tree_on('t015.txt')
    assert_equal 2,         t.array.size
    assert_equal 2,         t.array[0].array.size
    assert_match /^c\s*$/,  t.array[1].str
  end

  def test_str_node_break_on_sub_header
    t = build_tree_on('t018.txt')
    assert_equal 1,         t.array.size
    assert_match /^hi\s*$/, t.array[0].array[0].str
    assert_match /^ho\s*$/, t.array[0].array[1].array[0].str
  end

  def test_paragraph_break_on_whiteline
    t = build_tree_on('t019.txt')
    assert_equal 2,         t.array.size
    assert_match /^a\s*$/,  t.array[0].str
    assert_match /^b\s*$/,  t.array[1].str
  end

  def test_nested_header
    t = build_tree_on('t020.txt')
    assert_equal 1,         t.array.size
    assert_match /will be/, t.array[0].array[2].str
  end

  # v0.06.00 feature
  def test_quote_in_list
    t = build_tree_on('t021.txt')
    assert_equal 1,         t.array.size
    assert_equal 2,         t.array[0].array.size
    assert_equal 3,         t.array[0].array[0].array.size
  end

  # nested quote (e.g. source program) should be in 1 quote.
  def test_quote_with_several_nest_level
    t = build_tree_on('t022.txt')
    # 6 elements(text, quote, text, quote, list, text) at top level:
    assert_equal 6, t.array.size

    # 3rd element is quote and next is list:
    assert_equal Juli::Intermediate::StrNode,     t.array[3].class
    assert_equal Juli::Intermediate::OrderedList, t.array[4].class
  end

  # Workaround on test_quote_with_several_nest_level(test case = t022.txt)
  # was not enough.  With list, quote wasn't handled well;-(
  def test_quote_after_list
    t = build_tree_on('t023.txt')
    # 5 elements(text, list, text, quote, text) at top level:
    assert_equal 5, t.array.size
  end

  # header, quote, header, and then quote was not parsed correctly at v1.01.01
  def test_header_quote_without_list
    t = build_tree_on('t024.txt')
    assert_equal 2, t.array.size
    assert_equal 2, t.array[1].array.size
    assert_equal Juli::Intermediate::StrNode,
                 t.array[1].array[1].array[0].class
    assert_equal 2, t.array[1].array[1].array[0].level
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