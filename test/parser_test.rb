require 'test_helper'

class ParserTest < Test::Unit::TestCase
  def setup
    $stdout = File.open('/dev/null', 'w')
  end

  def teardown
    $stdout = STDOUT
  end

  def test_parse
    stdout_to_dev_null do
      for file in ['t001.txt', 't002.txt'] do
        assert_nothing_raised do
          Juli::Parser.new.parse(data_path(file), Visitor::Tree)
        end
      end
    end
  end

  def test_nested_ordered_list
    t = build_tree_on('t004.txt')
    assert_equal 1, t.array.size
    assert_equal Intermediate::OrderedList,     t.array[0].class
    assert_equal Intermediate::OrderedListItem, t.array[0].array[0].class
    assert_equal Intermediate::OrderedList,     t.array[0].array[1].class
  end

  # even if list order is incorrect, parser shouldn't failed and
  # it is recognized as top-level.
  def test_nested_ordered_list_incorrect
    assert_nothing_raised do
      parser = Juli::Parser.new
      parser.parse(data_path('t005.txt'), Visitor::Tree)
    end
  end

  def test_nested_unordered_list
    t = build_tree_on('t006.txt')
    assert_equal 1, t.array.size
    assert_equal Intermediate::UnorderedList,     t.array[0].class
    assert_equal Intermediate::UnorderedListItem, t.array[0].array[0].class
    assert_equal Intermediate::UnorderedList,     t.array[0].array[1].class
  end

  def test_nested_mixed_list
    t = build_tree_on('t007.txt')

    # [order-list, default, unorder-list]
    assert_equal 3, t.array.size
    assert_equal Intermediate::OrderedList,   t.array[0].class
    assert_equal Intermediate::UnorderedList, t.array[2].class

    # [order-item, unorder-list, order-item]
    assert_equal 3, t.array[0].array.size

    # [unorder-item, order-list, unorder-item]
    assert_equal 3, t.array[2].array.size
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
    parser.parse(data_path(test_file), Visitor::Tree)
    parser.tree
  end
end