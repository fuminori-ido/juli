require 'juli/wiki'

# intermediate tree nodes
module Juli::Intermediate
  class Node
    attr_accessor :parent

    def accept(visitor)
      visitor.visit_node(self)
    end
  end

  # StrNode adds 'concat' string manupilation method
  #
  # StrNode is also an element of ListItem
  class StrNode < Node
    attr_accessor :str, :level

    def initialize(str = '', level = 0)
      @str    = str
      @level  = level
    end

    def concat(str)
      @str += str
    end

    def accept(visitor)
      visitor.visit_str(self)
    end
  end

  class ArrayNode < Node
    attr_accessor :array, :level

    def initialize(level)
      @array  = Array.new
      @level  = level
    end

    def add(child)
      @array << child
      child.parent = self
      self
    end

    # find upper node than the 'level'
    def find_upper(level)
      if self.level < level
        self
      else
        if parent
          parent.find_upper(level)
        else
          raise "No parent node"
        end
      end
    end

    # fallback when no list parent on list.find_list
    def find_list(level)
      self
    end
  end

  # level==0 is top level array node.
  #
  # NOTE: @dom_id will be used for only Html visitor and contents helper.
  class HeaderNode < ArrayNode
    attr_accessor :str, :dom_id

    # === INPUTS
    # two patterns are considered:
    #
    # 1. absyn_header
    # 2. level & str
    def initialize(*absyn_header_or_values)
      super(absyn_header_or_values[0].class == Juli::Absyn::HeaderNode ?
          absyn_header_or_values[0].level :
          absyn_header_or_values[0])

      case absyn_header_or_values[0]
      when Juli::Absyn::HeaderNode
        @str    = absyn_header_or_values[0].str
      else
        @str    = absyn_header_or_values[1]
      end
    end
  
    def accept(visitor)
      visitor.visit_header(self)
    end
  end

  # abstract List.
  #
  # find_list() is Array method because to find parent
  # even if string is the following level:
  #
  #   |1. list item
  #   |Hello World
  #
  # On the other side, above 'Hello World' level is zero so
  # it must be added to header, not list.  In order to do that,
  # list level is calculated as depth + offset.
  class List < ArrayNode
    def initialize(level)
      super(level)
    end
    # find upper or equal *list* node than the 'level'
    #
    # NOTE: use find_upper() to find parent header while use
    # find_upper_list() to find parent *list* but implement here because:
    #
    # 1. header is added under parent while list item is added at the same
    #    level of list as follows:
    #
    #
    # Header:
    #   = a             H(a)
    #   == b        ->    | H(b)
    #   = c             H(c)
    #
    # List:
    #                   List
    #   1. a              | item(a)
    #     1. b      ->    | List
    #   1. c              | | item(b)
    #                     | item(c)
    def find_list(level)
      if self.level <= level
        self
      else
        if parent
          parent.find_list(level)
        else
          raise "No parent node"
        end
      end
    end
  end

  class OrderedList < List
    def initialize(level)
      super
    end

    def accept(visitor)
      visitor.visit_ordered_list(self)
    end
  end

  # ListItem is also an array-node, but it consists from only
  # StrNode and QuoteNode.
  #
  # ListItem has also level to track depth of child string.
  class ListItem < ArrayNode
    def initialize(level)
      super(level)
    end

    def find_list(level)
      parent.find_list(level)
    end
  end

  class OrderedListItem < ListItem
    def accept(visitor)
      visitor.visit_ordered_list_item(self)
    end
  end

  class UnorderedList < List
    def initialize(level)
      super
    end

    def accept(visitor)
      visitor.visit_unordered_list(self)
    end
  end

  class UnorderedListItem < ListItem
    def accept(visitor)
      visitor.visit_unordered_list_item(self)
    end
  end

  class DictionaryList < ArrayNode
    def initialize
      super(0)
    end
  
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

  # Abstract VISITOR-pattern around Intermediate tree.
  #
  # === How to add new generator
  # Document generator, which juli(1) command says, points to 'visitor'
  # internally because it is VISITOR-pattern.
  # After adding new visitor, for example PDF-generator,
  # it can be used by 'juli -g pdf' (let me assume the file name is pdf.rb).
  # Follow the steps below to add new visitor:
  #
  # 1. create LIB/juli/visitor/pdf.rb.  Probably, it is easy to copy
  #    from another visitor file (e.g. html.rb) as the skelton.
  #    Where, LIB is 'lib/' directory in package environment, or
  #    one of $LOAD_PATH in installed environment.
  # 1. implement the pdf.rb.  It's the most important task, of course...
  #
  class Visitor
    # Visitor object is initialized when juli(1) gen command is executed.
    # In other words, it is *NOT* initialized for each input text file.
    # Some global initialization can be done here.
    #
    # Take care that this is executed every juli(1) execution.
    def initialize(opts = {})
      @opts = opts.dup
    end

    # 'run' bulk-mode (when no files are specified at
    # juli(1) command line).  Derived class should implement this.
    def run_bulk; end

    # run for a file and its node-tree.
    # Here is just sample implementation.
    # Derived class can re-implement this.
    #
    # === INPUTS
    # in_file::   input filename
    # root::      Intermediate tree root
    def run_file(in_file, root)
      root.accept(self)
    end

    # Methods for each Intermediate node. Derived class should implement
    # these.
    #
    # === INPUTS
    # n:: Intermediate node
    def visit_node(n); end
    def visit_str(n); end
    def visit_header(n); end
    def visit_ordered_list(n); end
    def visit_ordered_list_item(n); end
    def visit_unordered_list(n); end
    def visit_unordered_list_item(n); end
    def visit_dictionary_list(n); end
    def visit_dictionary_list_item(n); end
  end
end
