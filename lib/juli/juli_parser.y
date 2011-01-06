# Text parser for Juli format.
#
# = FIXME
# Two pass (1. build Absyn tree, 2. build Intermediate tree) may be
# merged into one pass, but I couldn't do that.
class JuliParser
  options no_result_var

rule
  # Since Juli text is line-oriented syntax like wiki, 
  # Abstract syntax tree is fixed 6-level depth header.
  #
  # Racc action returns absyn node to build absyn-tree, while
  # @curr is current node to store current node
  text
    : elements            { @root = val[0] }

  elements
    : /* none */          { Absyn::ArrayNode.new }
    | elements element    { val[0].add(val[1]) }

  element
    : H STRING            { Absyn::HeaderNode.new(val[0], val[1]) }
    | ANY
    | ORDERED_LIST_ITEM   { Absyn::OrderedListItem.new(val[0]) }
    | UNORDERED_LIST_ITEM { Absyn::UnorderedListItem.new(val[0]) }
    | DT STRING           { Absyn::DictionaryListItem.new(val[0], val[1]) }
    | QUOTE               { Absyn::QuoteNode.new(val[0]) }
end

---- header
module Absyn
  class Node
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
      @array      = Array.new
    end
  
    def add(child)
      case child
      when String
        @array << DefaultNode.new(child)
      else
        @array << child
      end
      self
    end
  
    def accept(visitor)
      visitor.visit_array(self)
    end
  end
  
  class HeaderNode < Node
    attr_accessor :level, :str
  
    def initialize(level, str)
      @level  = level
      @str    = str
    end
  
    def accept(visitor)
      visitor.visit_header(self)
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

  class UnorderedListItem < Node
    attr_accessor :str
  
    def initialize(str)
      @str = str
    end
  
    def accept(visitor)
      visitor.visit_unordered_list_item(self)
    end
  end

  class DictionaryListItem < Node
    attr_accessor :term, :str
  
    def initialize(term, str)
      @term = term
      @str  = str
    end
  
    def accept(visitor)
      visitor.visit_dictionary_list_item(self)
    end
  end

  class QuoteNode < Node
    attr_accessor :str
  
    def initialize(str)
      @str  = str
    end
  
    def accept(visitor)
      visitor.visit_quote(self)
    end
  end

  class Visitor
    def visit_node(n); end
    def visit_array(n); end
    def visit_default(n); end
    def visit_header(n); end
    def visit_ordered_list_item(n); end
    def visit_unordered_list_item(n); end
    def visit_dictionary_list_item(n); end
    def visit_quote(n); end
  end
end

---- inner

# build Intermediate tree from Absyn tree.
#
#   h1
#   Orange
#   h2
#   Apple
#   h1
# ↓
#
#   h1
#   | +- Orange
#   | +- h2
#   |   +- Apple
#   h1
class TreeBuilder < Absyn::Visitor
  def initialize
    @curr_level = 999
    @root = @curr_header = Intermediate::HeaderNode.new(0, '(root)')
  end

  def root
    @root
  end

  def visit_array(n)
    for child in n.array do
      child.accept(self)
    end
  end

  def visit_default(n)
    list_break
    @curr_header.add(Intermediate::DefaultNode.new(n.str))
  end

  def visit_header(n)
    list_break
    new_node = Intermediate::HeaderNode.new(n)

    # When @curr_header points to upper (e.g. root) and parse level-1 as
    # follows, build new node under the upper and shift @curr_header to it:
    #
    #   (root)          - @curr_header
    #     test
    #     = NAME        - we are here!
    #     ...
    #
    if @curr_header.level < n.level
      @curr_header.add(new_node)

    # When @curr_header points to lower level (e.g. 'Option' below)
    # and parses 'SEE ALSO' (level=1) as follows, find parent, 
    # build new node under it, and shift @curr_header to the new node:
    #
    #   ...
    #   === Option      - @curr_header
    #   ...
    #   = SEE ALSO      - we are here!
    else
      @curr_header.find_upper(n.level).add(new_node)
    end
    @curr_header = new_node
  end

  def visit_ordered_list_item(n)
    if !@curr_list
      @curr_list = Intermediate::OrderedList.new
      @curr_header.add(@curr_list)
    end
    @curr_list.add(Intermediate::OrderedListItem.new(n.str))
  end

  def visit_unordered_list_item(n)
    if !@curr_list
      @curr_list = Intermediate::UnorderedList.new
      @curr_header.add(@curr_list)
    end
    @curr_list.add(Intermediate::UnorderedListItem.new(n.str))
  end

  def visit_dictionary_list_item(n)
    if !@curr_list
      @curr_list = Intermediate::DictionaryList.new
      @curr_header.add(@curr_list)
    end
    @curr_list.add(Intermediate::DictionaryListItem.new(n))
  end

  def visit_quote(n)
    if !@curr_quote
      @curr_quote = Intermediate::QuoteNode.new
      @curr_header.add(@curr_quote)
    end
    @curr_quote.str += n.str
  end

private
  def list_break
    @curr_list  = nil
    @curr_quote = nil
  end
end

  require 'erb'
  require 'juli/visitor'

  # parse one file, build Intermediate tree, then generate HTML
  def parse(in_file, visitor)
    File.open(in_file) do |io|
      @in_io = io
      yyparse self, :scan
    end
    tree = TreeBuilder.new
    @root.accept(tree)
    visitor.new.run(in_file, tree.root)
  end

private
  def scan(&block)
    @block_str = ''
    while line = @in_io.gets do
      case line
      when /^\s*$/
        block_break(&block)
        @block_str = ''
        # clear block_str and skip empty line
      when /^=\s+(.*)$/
        header(1, $1, &block)
      when /^==\s+(.*)$/
        header(2, $1, &block)
      when /^===\s+(.*)$/
        header(3, $1, &block)
      when /^====\s+(.*)$/
        header(4, $1, &block)
      when /^=====\s+(.*)$/
        header(5, $1, &block)
      when /^======+\s+(.*)$/
        header(6, $1, &block)
      when /^\d+\.\s+(.*)$/
        block_break(&block)
        yield :ORDERED_LIST_ITEM, $1
      when /^\*\s+(.*)$/
        block_break(&block)
        yield :UNORDERED_LIST_ITEM, $1
      when /^(.*)::\s*(.*)$/
        block_break(&block)
        yield :DT, $1
        yield :STRING, $2
      when /^(\s+)(.*)$/
        yield :QUOTE, $2 + "\n"
      else
        @block_str += line
      end
    end
    block_break(&block)
    yield false, nil
  end

  # block break happens, so proess block
  def block_break(&block)
    if @block_str != ''
      yield :ANY, @block_str
    end
  end

  # process block, then process header
  def header(level, string, &block)
    block_break(&block)
    yield :H,       level
    yield :STRING,  string
  end

---- footer
