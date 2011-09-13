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

  class Verbatim < Node
    attr_accessor :str

    def initialize(str)
      @str    = str
    end

    def accept(visitor)
      visitor.visit_verbatim(self)
    end
  end

  class ArrayNode < Node
    attr_accessor :array

    def initialize
      @array  = Array.new
    end

    def accept(visitor)
      visitor.visit_array(self)
    end

    def add(child)
      @array << child
      child.parent = self
      self
    end
  end

  # NOTE: @dom_id will be used for only Html visitor and contents helper.
  class Chapter < Node
    attr_accessor :level, :str, :blocks, :dom_id

    def initialize(level, str, blocks)
      super()
      @level  = level
      @str    = str
      @blocks = blocks
    end
  
    def accept(visitor)
      visitor.visit_chapter(self)
    end
  end

  # abstract List.
  class List < ArrayNode
  end

  class OrderedList < List
    def accept(visitor)
      visitor.visit_ordered_list(self)
    end
  end

  # ListItem is also an array-node, but it consists from only
  # StrNode and QuoteNode.
  #
  # ListItem has also level to track depth of child string.
  class ListItem < ArrayNode
    def initialize(str)
      super()
      self.add(StrNode.new(str))
    end
  end

  class OrderedListItem < ListItem
    def accept(visitor)
      visitor.visit_ordered_list_item(self)
    end
  end

   class UnorderedList < List
    def accept(visitor)
      visitor.visit_unordered_list(self)
    end
  end

  class UnorderedListItem < ListItem
    def accept(visitor)
      visitor.visit_unordered_list_item(self)
    end
  end

  # (Compact) Dictionary list as follows:
  #   term1:: description1
  #   term2:: description2
  #   ...
  #
  # === SEE ALSO
  # LongDictionaryList
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

  # (Long) Dictionary list as follows:
  #   term1::
  #     description1
  #     description1(cont'd)
  #   term2::
  #     description2
  #   ...
  #
  # Description can be a paragraph.
  #
  # === SEE ALSO
  # DictionaryList
  class LongDictionaryList < List
    def initialize(level)
      super(level)
    end
  
    def accept(visitor)
      visitor.visit_long_dictionary_list(self)
    end
  end

  # LongDictionaryListItem consists from term and array-node
  class LongDictionaryListItem < ArrayNode
    attr_accessor :term

    def initialize(term, level)
      @term = term
      super(level)
    end
  
    def accept(visitor)
      visitor.visit_long_dictionary_list_item(self)
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
    def visit_verbatim(n); end
    def visit_array(n)
      for node in n.array do
        node.accept(self)
      end
    end
    def visit_chapter(n); end
    def visit_ordered_list(n); end
    def visit_ordered_list_item(n); end
    def visit_unordered_list(n); end
    def visit_unordered_list_item(n); end
    def visit_dictionary_list(n); end
    def visit_dictionary_list_item(n); end
    def visit_long_dictionary_list(n); end
    def visit_long_dictionary_list_item(n); end
  end
end
