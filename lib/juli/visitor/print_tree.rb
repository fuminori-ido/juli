module Visitor
  class PrintTree < Intermediate::Visitor
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
      printf "DefaultNode(%s)\n", str.size > 30 ? str[0..30] + '...' : str
    end
  
    def visit_header(n)
      print_depth
      printf("HeaderNode(%d %s)\n", n.level, n.name)
      @depth += 1
      for child in n.array do
        child.accept(self)
      end
      @depth -= 1
    end
  end
end