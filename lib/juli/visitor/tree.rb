require 'juli/intermediate'
require 'juli/util'
require 'juli/line_parser.tab'

module Juli::Visitor
  class LineTree < Juli::LineAbsyn::Visitor
    def initialize(depth)
      @depth = depth
    end

    def print_depth
      print '| ' * @depth
    end

    def visit_string(n)
      print_depth
      printf "Str:  %s\n", str_limit(n.str.gsub(/\n/, ''))
    end

    def visit_wikiname(n)
      print_depth
      printf "Wiki: %s\n", str_limit(n.str.gsub(/\n/, ''))
    end
  end

  # Another VISITOR-pattern for Intermediate tree to print tree
  # structure around each node.
  class Tree < Juli::Intermediate::Visitor
    include Juli::Util

    def initialize
      super
      @depth = 0
    end
  
    def print_depth
      print '| ' * @depth
    end
  
    def visit_default(n)
      print_depth
      printf("Default\n")
      @depth += 1
      n.line.accept(LineTree.new(@depth))
      @depth -= 1
    end
  
    def visit_header(n)
      print_depth
      printf("HeaderNode(%d %s)\n", n.level, n.str)
      @depth += 1
      for child in n.array do
        child.accept(self)
      end
      @depth -= 1
    end

    def visit_ordered_list(n)
      visit_list("OrderedList\n", n)
    end

    def visit_ordered_list_item(n)
      visit_list_item("OrderedListItem\n", n)
    end

    def visit_unordered_list(n)
      visit_list("UnorderedList\n", n)
    end

    def visit_unordered_list_item(n)
      visit_list_item("UnorderedListItem\n", n)
    end

    def visit_dictionary_list(n)
      visit_list("DictionaryList\n", n)
    end

    def visit_dictionary_list_item(n)
      print_depth
      printf("DictionaryListItem\n")
      @depth += 1
      n.term.accept(LineTree.new(@depth))
      n.line.accept(LineTree.new(@depth))
      @depth -= 1
    end

    def visit_quote(n)
      print_depth
      printf("QuoteNode(%s)\n", str_limit(n.str).gsub(/\n/m, '<\n>'))
    end

    # visit root to generate intermediate-tree structure.
    def run(in_file, root)
      root.accept(self)
    end

  private
    def visit_list(class_str, n)
      print_depth
      printf(class_str)
      @depth += 1
      for child in n.array do
        child.accept(self)
      end
      @depth -= 1
    end

    def visit_list_item(class_str, n)
      print_depth
      printf(class_str)
      @depth += 1
      n.line.accept(LineTree.new(@depth))
      @depth -= 1
    end
  end
end