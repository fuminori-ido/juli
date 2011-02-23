require 'juli/intermediate'
require 'juli/util'
require 'juli/line_parser.tab'

module Juli::Visitor
  class LineTree < Juli::LineAbsyn::Visitor
    include Juli::Util

    def initialize(depth)
      @depth = depth
    end

    def print_depth
      print '| ' * @depth
    end

    def visit_string(n)
      print_depth
      printf "str:  %s\n", str_limit(n.str.gsub(/\n/, '\n'))
    end

    def visit_wikiname(n)
      print_depth
      printf "wiki: %s\n", str_limit(n.str.gsub(/\n/, '\n'))
    end

    def visit_url(n)
      print_depth
      printf "url:  %s\n", str_limit(n.str.gsub(/\n/, '\n'))
    end
  end

  # Another VISITOR-pattern for Intermediate tree to print tree
  # structure around each node.
  class Tree < Juli::Intermediate::Visitor
    include Juli::Util

    # visit root to generate intermediate-tree structure.
    def run_file(in_file, root)
      @depth = 0
      super
    end
  
    def visit_paragraph(n)
      print_depth
      printf("Paragraph\n")
      @depth += 1
      process_str(n.str)
      @depth -= 1
    end

    def visit_str(n)
      print_depth
      printf("StrNode\n")
      @depth += 1
      process_str(n.str)
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
      process_str(n.term)
      process_str(n.str)
      @depth -= 1
    end

    def visit_quote(n)
      print_depth
      printf("QuoteNode(%s)\n", str_limit(n.str).gsub(/\n/m, '<\n>'))
    end

  private
    def print_depth
      print '| ' * @depth
    end
  
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
      for str_or_quote in n.array do
        str_or_quote.accept(self)
      end
      @depth -= 1
    end

    # str -> Juli::LineAbsyn -> print with depth
    def process_str(str)
      Juli::LineParser.new.parse(str, Juli::Wiki.wikinames).
          accept(LineTree.new(@depth))
    end
  end
end