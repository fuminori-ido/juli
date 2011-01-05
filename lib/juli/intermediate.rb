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

  class ArrayNode < Node
    attr_accessor :array

    def initialize
      @array  = Array.new
    end

    def add(child)
      @array << child
      child.parent = self
      self
    end
  end

  # level==0 is top level array node.
  #
  # NOTE: @dom_id will be used for only Html visitor and contents helper.
  class HeaderNode < ArrayNode
    attr_accessor :level, :str, :dom_id

    # === INPUTS
    # two patterns are considered:
    #
    # 1. absyn_header
    # 2. level & str
    def initialize(*absyn_header_or_values)
      super()
      case absyn_header_or_values[0]
      when Absyn::HeaderNode
        @level  = absyn_header_or_values[0].level
        @str    = absyn_header_or_values[0].str
      else
        @level  = absyn_header_or_values[0]
        @str    = absyn_header_or_values[1]
      end
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

  class OrderedList < ArrayNode
    def accept(visitor)
      visitor.visit_ordered_list(self)
    end
  end

  class OrderedListItem < Node
    attr_accessor :str
  
    def initialize(str)
      @str = str
    end
  
    def accept(visitor)
      visitor.visit_ordered_list_item(self)
    end
  end

  class UnorderedList < ArrayNode
    def accept(visitor)
      visitor.visit_unordered_list(self)
    end
  end

  class UnorderedListItem < Node
    attr_accessor :str
  
    def initialize(str)
      @str = str
    end
  
    def accept(visitor)
      visitor.visit_unordered_list_item(self)
    end
  end

  class DictionaryList < ArrayNode
    def accept(visitor)
      visitor.visit_dictionary_list(self)
    end
  end

  class DictionaryListItem < Node
    attr_accessor :term, :str
  
    def initialize(absyn_dictionary_list_item)
      @term = absyn_dictionary_list_item.term
      @str  = absyn_dictionary_list_item.str
    end
  
    def accept(visitor)
      visitor.visit_dictionary_list_item(self)
    end
  end
  
  class Visitor
    def visit_node(n); end
    def visit_default(n); end
    def visit_header(n); end
    def visit_ordered_list(n); end
    def visit_ordered_list_item(n); end
    def visit_unordered_list(n); end
    def visit_unordered_list_item(n); end
    def visit_dictionary_list(n); end
    def visit_dictionary_list_item(n); end

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
