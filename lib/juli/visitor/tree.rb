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
      print_depth
      printf("OrderList\n")
      @depth += 1
      for child in n.array do
        child.accept(self)
      end
      @depth -= 1
    end

    def visit_ordered_list_item(n)
      print_depth
      printf("OrderedListItem(%s)\n", str_limit(n.str))
    end

    # visit root to generate intermediate-tree structure.
    def run(in_file, root)
      root.accept(self)
    end

  private
    def str_limit(str)
      str.size > 30 ? str[0..30] + '...' : str
    end
  end
end