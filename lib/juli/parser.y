# Text parser for Juli format.
#
# = FIXME
# Two pass (1. build Absyn tree, 2. build Intermediate tree) may be
# merged into one pass, but I couldn't do that.
class Juli::Parser
  options no_result_var

rule
  # Since Juli text is line-oriented syntax like wiki, 
  # Abstract syntax tree is fixed 6-level depth header.
  #
  # Racc action returns absyn node to build absyn-tree, while
  # @curr is current node to store current node
  text
    : elements                  { @root = val[0]; @root.add(Absyn::End.new) }
  elements
    : /* none */                { Absyn::ArrayNode.new }
    | elements element          { val[0].add(val[1]) }

  element
    : H STRING                  { Absyn::HeaderNode.new(val[0], val[1]) }
    | LEVEL ORDERED_LIST_ITEM   { Absyn::OrderedListItem.new(val[0], val[1]) }
    | LEVEL UNORDERED_LIST_ITEM { Absyn::UnorderedListItem.new(val[0], val[1]) }
    | DT STRING                 { Absyn::DictionaryListItem.new(val[0], val[1]) }
    | WHITELINE                 { Absyn::WhiteLine.new }
    | LEVEL STRING              { Absyn::StringNode.new(val[0], val[1]) }
end

---- header
require 'juli/wiki'

module Juli::Absyn
  class Node
    include Juli::Wiki

    def accept(visitor)
      visitor.visit_node(self)
    end
  end

  # let Visitor know end of visiting
  class End < Node
    def accept(visitor)
      visitor.visit_end(self)
    end
  end

  class StringNode < Node
    attr_accessor :level, :str
  
    def initialize(level, str)
      @level  = level
      @str    = str
    end
  
    def accept(visitor)
      visitor.visit_string(self)
    end
  end
  
  class ArrayNode < Node
    attr_accessor :array
  
    def initialize
      @array      = Array.new
    end
  
    def add(child)
      @array << child
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
    attr_accessor :level, :line
  
    def initialize(level, str)
      @level  = level
      @line   = Juli::LineParser.new.parse(str, wikinames)
    end
  
    def accept(visitor)
      visitor.visit_ordered_list_item(self)
    end
  end

  class UnorderedListItem < Node
    attr_accessor :level, :line
  
    def initialize(level, str)
      @level  = level
      @line   = Juli::LineParser.new.parse(str, wikinames)
    end
  
    def accept(visitor)
      visitor.visit_unordered_list_item(self)
    end
  end

  class DictionaryListItem < Node
    attr_accessor :term, :line
  
    def initialize(term, str)
      @term = Juli::LineParser.new.parse(term,  wikinames)
      @line = Juli::LineParser.new.parse(str,   wikinames)
    end
  
    def accept(visitor)
      visitor.visit_dictionary_list_item(self)
    end
  end

  class WhiteLine < Node
    def accept(visitor)
      visitor.visit_white_line(self)
    end
  end

  class Visitor
    def visit_node(n); end
    def visit_array(n); end
    def visit_string(n); end
    def visit_header(n); end
    def visit_ordered_list_item(n); end
    def visit_unordered_list_item(n); end
    def visit_dictionary_list_item(n); end
    def visit_white_line(n); end
    def visit_end(n); end
  end
end

---- inner

# build Intermediate tree from Absyn tree.
#
# Before:
#   h1
#   Orange
#   h2
#   Apple
#   h1
# ↓
#
# After:
#   h1
#   | +- Orange
#   | +- h2
#   |   +- Apple
#   h1
#
# === Header
# As seen Before & After above, flat header (where i=1..6) is 
# organized in tree by finding its level.
#
# === List
# When level keeps the same, each type list item is in the same list.
# When deeper level list item comes, create new list.
# When shallow level list item comes, ends the list until the same level.
# This is the same search logic as header's.
#
# === Baseline
# Same concept as rdtools.  It is indent or offset from begging of a line.
# deeper level string is interpreted as Quote.
# 
class TreeBuilder < Absyn::Visitor
  def initialize
    @root       = Intermediate::HeaderNode.new(0, '(root)')

    # following instance vars are to keep 'current' header, list, array,
    # str_block, and baseline while parsing Absyn tree:
    @header     = @root
    @list       = nil
    @array      = @root   # points to header or list
    @str_block  = ''
    @baseline   = 0
  end

  def root
    @root
  end

  def visit_array(n)
    for child in n.array do
      child.accept(self)
    end
  end

  def visit_string(n)
    if n.level > @baseline        # beginning of quote
      str_block_break
      @str_block = n.str
    elsif n.level == @baseline    # same baseline
      @str_block += n.str
    else                          # end of quote -> flush it
      @array.add(Intermediate::QuoteNode.new(@str_block))
      @str_block = n.str    # beginning of new str_block
    end
    @baseline = n.level
  end

  def visit_header(n)
    list_break
    new_node = Intermediate::HeaderNode.new(n)

    # When @header points to upper (e.g. root) and parse level-1 as
    # follows, build new node under the upper and shift @header to it:
    #
    #   (root)          - @header
    #     test
    #     = NAME        - we are here!
    #     ...
    #
    if @header.level < n.level
      @header.add(new_node)

    # When @header points to lower level (e.g. 'Option' below)
    # and parses 'SEE ALSO' (level=1) as follows, find parent, 
    # build new node under it, and shift @header to the new node:
    #
    #   ...
    #   === Option      - @header
    #   ...
    #   = SEE ALSO      - we are here!
    else
      @header.find_upper(n.level).add(new_node)
    end
    @array = @header = new_node
  end

  def visit_ordered_list_item(n)
    visit_list_item(n, 
        Intermediate::OrderedList,
        Intermediate::OrderedListItem)
  end

  def visit_unordered_list_item(n)
    visit_list_item(n,
        Intermediate::UnorderedList,
        Intermediate::UnorderedListItem)
  end

  def visit_dictionary_list_item(n)
    if !@list
      @list = Intermediate::DictionaryList.new
      @header.add(@list)
    end
    @list.add(Intermediate::DictionaryListItem.new(n))
  end

  # if baseline > 0, treat as continous of quote
  def visit_white_line(n)
    if @baseline > 0
      @str_block += "\n"
    else
      list_break
    end
  end

  # flush every buffer
  def visit_end(n)
    list_break
  end

private
  # action on end of string block
  def str_block_break
    if @str_block != ''
      @array.add(
          @baseline == 0 ?
              Intermediate::DefaultNode.new(@str_block) :
              Intermediate::QuoteNode.new(@str_block))
    end
    @str_block  = ''
    @baseline   = 0
  end

  # action on end of list
  def list_break
    str_block_break
    @list  = nil
    @array = @header
  end

  def visit_list_item(n, list_class, list_item_class)
    str_block_break

    # when same level, add to curr_list
    if @list && @list.level == n.level
      @list.add(list_item_class.new(n.line))

    # when @list points to upper or nil and parses lower(=nested) list,
    # build new list node under the upper and shift @list to it:
    elsif !@list || @list.level < n.level
      new_list  = list_class.new(n.level)
      @array.add(new_list)
      new_list.add(list_item_class.new(n.line))
      @list = @array = new_list

    # when @list points to lower and parses upper, find parent,
    # build new node under it, and shift @list to it:
    else
      parent_list = @list.find_upper_or_equal(n.level)
      parent_list.add(list_item_class.new(n.line))
      @list = @array = parent_list
    end
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
    @tree = TreeBuilder.new
    @root.accept(@tree)
    visitor.run_file(in_file, @tree.root)
  end

  # return intermediate tree
  def tree
    @tree.root
  end

private
  class ScanError < Exception; end

  def scan(&block)
    while line = @in_io.gets do
      case line
      when /^\s*$/
        yield :WHITELINE, nil
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
      when /^(\s*)\d+\.\s+(.*)$/
        yield :LEVEL,             $1.length
        yield :ORDERED_LIST_ITEM, $2
      when /^(\s*)\*\s+(.*)$/
        yield :LEVEL,               $1.length
        yield :UNORDERED_LIST_ITEM, $2
      when /^(\S.*)::\s*(.*)$/
        yield :DT, $1
        yield :STRING, $2
      when /^(\s*)(.*)$/
        yield :LEVEL,   $1.length
        yield :STRING,  $2 + "\n"
      else
        raise ScanError
      end
    end
    yield false, nil
  end

  # process block, then process header
  def header(level, string, &block)
    yield :H,       level
    yield :STRING,  string
  end

---- footer
