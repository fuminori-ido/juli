module Visitor
  class Tree < Intermediate::Visitor
    def initialize
      super
      @depth = 0
    end
  
    def print_depth
      print '| ' * @depth
    end
  
    def visit_default(n)
      print_depth
      str = n.str.gsub(/\n/, '')
      printf "DefaultNode(%s)\n", str_limit(str)
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
      visit_list_item("OrderedListItem(%s)\n", n)
    end

    def visit_unordered_list(n)
      visit_list("UnorderedList\n", n)
    end

    def visit_unordered_list_item(n)
      visit_list_item("UnorderedListItem(%s)\n", n)
    end

    def visit_dictionary_list(n)
      visit_list("DictionaryList\n", n)
    end

    def visit_dictionary_list_item(n)
      print_depth
      printf("DictionaryListItem(%s, %s)\n", n.term, str_limit(n.str))
    end

    def visit_quote(n)
      print_depth
      printf("QuoteNode(%s)\n", str_limit(n.str))
    end

    # visit root to generate intermediate-tree structure.
    def run(in_file, root)
      root.accept(self)
    end

  private
    def str_limit(str)
      str.size > 30 ? str[0..30] + '...' : str
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
      printf(class_str, str_limit(n.str))
    end
  end
end