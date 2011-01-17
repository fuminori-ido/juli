require 'juli/wiki'

# intermediate tree nodes
module Juli::Intermediate
  class Node
    attr_accessor :parent

    def accept(visitor)
      visitor.visit_node(self)
    end
  end
  
  class DefaultNode < Node
    attr_accessor :line

    def initialize(str)
      @line = Juli::LineParser.new.parse(str, Juli::Wiki.wikinames)
    end

    def accept(visitor)
      visitor.visit_default(self)
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

    # find upper or equal level node than the 'level'
    #
    # NOTE: use find_upper() to find header parent while use
    # find_upper_or_equal() to find list parent because
    # header is added under parent while list item is added at the same
    # level of list as follows:
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
    def find_upper_or_equal(level)
      if self.level <= level
        self
      else
        if parent
          parent.find_upper_or_equal(level)
        else
          raise "No parent node"
        end
      end
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

  class OrderedList < ArrayNode
    def initialize(level)
      super
    end

    def accept(visitor)
      visitor.visit_ordered_list(self)
    end
  end

  class OrderedListItem < Node
    attr_accessor :line
  
    def initialize(line)
      @line = line
    end
  
    def accept(visitor)
      visitor.visit_ordered_list_item(self)
    end
  end

  class UnorderedList < ArrayNode
    def initialize(level)
      super
    end

    def accept(visitor)
      visitor.visit_unordered_list(self)
    end
  end

  class UnorderedListItem < Node
    attr_accessor :line
  
    def initialize(line)
      @line = line
    end
  
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
    attr_accessor :term, :line

    def initialize(absyn_dictionary_list_item)
      @term = absyn_dictionary_list_item.term
      @line = absyn_dictionary_list_item.line
    end
  
    def accept(visitor)
      visitor.visit_dictionary_list_item(self)
    end
  end

  class QuoteNode < Node
    attr_accessor :str

    # trim last white spaces
    def initialize(str)
      @str = str.gsub(/\s+\z/m, '')
    end

    def accept(visitor)
      visitor.visit_quote(self)
    end
  end
  
  # define VISITOR-pattern around Intermediate tree.
  #
  # === How to add new generator
  # Document generator, which juli(1) command says, points to 'visitor'
  # internally because it is VISITOR-pattern.
  # When adding new visitor, for example PDF-generator,
  # can be used by 'juli -g pdf' (let me assume the file name is pdf.rb).
  # Here is the step how to add new visitor:
  #
  # 1. create lib/juli/visitor/pdf.rb.  Probably, it is easy to copy
  #    from another visitor file (e.g. html.rb).
  # 1. implement the pdf.rb.  Most important taks, of course...
  #
  class Visitor
    # 'init' is invoked at bulk-mode on every juli(1) command execution
    # when this generator is specified so that the calling frequency
    # is the same as run-method.  However, the purpose is different.
    # That is the reason why two methods exist.
    # Derived class should implement this.
    def self.init; end

    # 'run' is invoked at bulk-mode (when no files are specified at
    # juli(1) command line).  Derived class should implement this.
    #
    # === INPUTS
    # opts::  option hash
    def self.run(opts={}); end

    def visit_node(n); end
    def visit_default(n); end
    def visit_header(n); end
    def visit_ordered_list(n); end
    def visit_ordered_list_item(n); end
    def visit_unordered_list(n); end
    def visit_unordered_list_item(n); end
    def visit_dictionary_list(n); end
    def visit_dictionary_list_item(n); end
    def visit_quote(n); end

    # run whole action for tree.
    # Here is just sample implementation.
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
