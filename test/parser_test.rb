require 'test_helper'


class ParserTest < Test::Unit::TestCase
  def setup
    #$stdout = File.open('/dev/null', 'w')

    # set juli_repo since parser referes it
    Juli::Util.juli_repo(File.join(File.dirname(__FILE__), 'repo'))
  end

  def teardown
    #$stdout = STDOUT
  end

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
    assert_equal 7, t.array.size
    assert_equal Juli::Intermediate::QuoteNode,   t.array[5].class
    assert_equal Juli::Intermediate::HeaderNode,  t.array[6].class
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
    assert_equal Juli::Intermediate::ParagraphNode, t.array[2].class
    assert_equal Juli::Intermediate::QuoteNode,   t.array[3].class
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