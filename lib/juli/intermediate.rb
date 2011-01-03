module Intermediate
  class Node
    attr_accessor :parent

    def accept(visitor)
      visitor.visit_node(self)
    end
  end
  
  class DefaultNode < Node
    attr_accessor :str

    def initialize(str)
      @str = str
    end

    def accept(visitor)
      visitor.visit_default(self)
    end
  end
  
  # level==0 is top level array node.
  class HeaderNode < Node
    attr_accessor :array, :level, :name

    # === INPUTS
    # two patterns are considered:
    #
    # 1. absyn_header
    # 2. level & name
    def initialize(*absyn_header_or_values)
      @array  = Array.new
      case absyn_header_or_values[0]
      when Absyn::HeaderNode
        @level  = absyn_header_or_values[0].level
        @name   = absyn_header_or_values[0].name
      else
        @level  = absyn_header_or_values[0]
        @name   = absyn_header_or_values[1]
      end
    end

    def add(child)
      @array << child
      child.parent = self
      self
    end
  
    def accept(visitor)
      visitor.visit_header(self)
    end

    # find upper header node than the 'level'
    def find_upper(level)
      if self.level < level
        self
      else
        parent.find_upper(level)
      end
    end
  end
  
  class Visitor
    def visit_node(n); end
    def visit_default(n); end
    def visit_header(n); end

    # run whole action for tree.  This is just sample implementation.
    # Derived class must implement this method.
    #
    # === INPUTS
    # in_file::   input filename
    # root::      Intermediate tree root
    def run(in_file, root)
      root.accept(self)
    end
  end
end
