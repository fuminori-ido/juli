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
    | ORDERED_LIST_ITEM         { Absyn::OrderedListItem.new(*val[0]) }
    | UNORDERED_LIST_ITEM       { Absyn::UnorderedListItem.new(*val[0]) }
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
      @array  = Array.new
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

  #   |   1. HelloWorld
  #    <----><-----------
  #    level    str
  class OrderedListItem < Node
    attr_accessor :level, :str
  
    def initialize(level, str)
      @level  = level
      @str    = str
    end
  
    def accept(visitor)
      visitor.visit_ordered_list_item(self)
    end
  end

  #   |   *  HelloWorld
  #    <----><-----------
  #    level    str
  class UnorderedListItem < Node
    attr_accessor :level, :str
  
    def initialize(level, str)
      @level  = level
      @str    = str
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
# When:
# level keeps the same:           each type list item is in the same list.
# deeper level list item comes:   create new list.
# shallow level list item comes:  ends the list until the same level.
#
# This is the same search logic as header's.
#
# === Offset
# Offset is a start point of text or list.
#
# For example, it is 0 in normal text, 2 in 1st level unordered list,
# 3 in 1st level numbered list, 4 in 2nd level unordered list, ....
# When there is the following text:
#
#   |Hello, World
#   |
#   |* Unordered list item A.
#   |* Unordered list item B.
#   |  * Nested Unordered list item B-1.
#   |
#   |1. Ordred list item A.
#   |1. Ordred list item B.
#
# then, each offset is as follows:
#
#    0 offset in normal list:
#
#   |Hello, World
#
#   <-> 2 offset in 1st level unordred list:
#   |
#   |* Unordered list item A.
#   |* Unordered list item B.
#
#   <---> 4 offset in 2nd level unordered list:
#   |
#   |  * Nested Unordered list item B-1.
#
#   <--> 3 offset in 1st level ordered list:
#   |
#   |1. Ordred list item A.
#   |1. Ordred list item B.
#
# === QuoteLevel
# It indicates quotation's start point.  Combination of Offset and QuoteLevel
# defines the operation type.  See quote_level.ods file for more detail.
# 
class TreeBuilder < Absyn::Visitor
  def initialize
    @root         = Intermediate::HeaderNode.new(0, '(root)')

    # following instance vars are to keep 'current' header, list_item, 
    # array, str_node, and quote_level while parsing Absyn tree:
    @header       = @root
    @list_item    = nil
    @array        = @root   # points to header, list, or even list-item

    # NOTE: str_node is a buffer.  Adding to node tree is differred
    # as possible since there is no actual string right now.
    @str_node     = Intermediate::StrNode.new
    @in_quote     = false
    @offset       = 0
    @quote_level  = 0
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
    vs_debug("start #{@quote_level} to #{n.level}", '')
    vs_debug('array is: ',  @array.class.to_s.split('::').last +
                                " level-#{@array.level}")
    if @quote_level==@offset && @quote_level < n.level
      # blue zone(see quote_level.ods)
      str_node_break
      vs_debug('beginning of quote', n.str)
      @in_quote = true
      @str_node = Intermediate::StrNode.new(n.str, n.level); @array.add(@str_node)
      @quote_level = n.level
    elsif @quote_level == n.level ||
          @quote_level > @offset &&  @quote_level < n.level
      # yellow zone
      vs_debug('same quote_level', n.str)
      @str_node.concat(' ' * (n.level - @quote_level) + n.str)
    else
      # red zone
      vs_debug('end of quote', n.str)

      # break list(= discard current @array) if n level is upper
      # than @array.level.
      list_break if n.level < @array.level

      @in_quote = case @array
                  when Intermediate::ListItem
                    n.level > @array.level
                  when  Intermediate::HeaderNode
                    n.level > 0
                  else
                    false
                  end
      @str_node = Intermediate::StrNode.new(n.str, n.level)

      vs_debug('add to array',  @array.class.to_s.split('::').last +
                                "level(#{@array.level})")
      # NOTE: add to parent here since n.str exists
      @array.add(@str_node)
      @quote_level = n.level
    end
  end

  def visit_header(n)
    vs_debug('', n.str, 'visit_header')
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

    # NOTE: Adding to node tree is differred
    # as possible since there is no actual string right now.
    @str_node = Intermediate::StrNode.new
    @in_quote = false
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
    list = if !@list_item
              l = Intermediate::DictionaryList.new
              @header.add(l)
              l
           else
             @list_item.parent
           end
    @list_item = Intermediate::DictionaryListItem.new(n)
    list.add(@list_item)
  end

  def visit_white_line(n)
    vs_debug('', '', 'visit_white_line')
    if in_quote?
      @str_node.concat("\n")
    else
      list_break
    end
  end

  # flush every buffer
  def visit_end(n)
    str_node_break
  end

private
  def in_quote?
    @in_quote
  end

  # print debug info when DEBUG environment is set.
  def vs_debug(tag, str, method='visit_string')
    return if !ENV['DEBUG']

    printf("%-20.20s %-20.20s '%s'\n",
        method,
        tag,
        str_limit(str).gsub(/\n/, '\n'))
  end

  # str_node_break is called when:
  # 1. beginning of quote
  # 1. list break
  # 1. end of input file
  #
  # to do:
  # 1. if parent is not set, add to @array.
  #    This happens for example at the beginning of text.
  # 1. create new str_node
  def str_node_break
    if @str_node.str !~ /\A\s*\z/m && !@str_node.parent
      @array.add(@str_node)
      vs_debug('add to parent:', @str_node.str, 'str_node_break')
    end

    @str_node = Intermediate::StrNode.new
    @in_quote = false
  end

  def list_level
    @list_item.parent.level
  end

  # action on end of list
  def list_break
    str_node_break
    vs_debug('', '', 'list_break')
    return if !@list_item

    @list_item    = nil
    @array        = @header
    @str_node     = Intermediate::StrNode.new
    @in_quote     = false
    @offset       = 0
    @quote_level  = 0
  end

  def visit_list_item(n, list_class, list_item_class)
    str_node_break
    @str_node = Intermediate::StrNode.new(n.str)
    list_item = list_item_class.new(n.level)
    list_item.add(@str_node)

    # when same level, add to curr_list
    if @list_item && list_level == n.level
      vs_debug('same level', n.str, 'visit_list_item')
      @list_item.parent.add(list_item)

    # when list points to upper or nil and parses lower(=nested) list,
    # build new list node under the upper and shift list to it:
    elsif !@list_item || list_level < n.level
      vs_debug('deeper level', n.str, 'visit_list_item')
      new_list  = list_class.new(n.level)
      add_list_to_array(new_list)
      new_list.add(list_item)

    # when list points to lower and parses upper, find parent,
    # build new node under it, and shift list to it:
    else
      vs_debug('shallow level', n.str, 'visit_list_item')
      parent_list = @list_item.parent.find_list(n.level)
      parent_list.add(list_item)
    end
    @array  = @list_item    = list_item
    @offset = @quote_level  = n.level
  end

  # if array is Header, add to it.
  # if array is ListItem, add to the parent.
  def add_list_to_array(list)
    if @array.is_a?(Juli::Intermediate::HeaderNode)
      @array.add(list)
    elsif @array.is_a?(Juli::Intermediate::ListItem)
      @array.parent.add(list)
    else
      raise "unknown array class"
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
      when /^(={1,6})\s+(.*)$/
        yield :H,       $1.length
        yield :STRING,  $2
      when /^(\s*)(\d+\.\s+)(.*)$/
        yield :ORDERED_LIST_ITEM, [$1.length + $2.length, $3 + "\n"]
      when /^(\s*)(\*\s+)(.*)$/
        yield :UNORDERED_LIST_ITEM, [$1.length + $2.length, $3 + "\n"]
      when /^(\S.*)::\s+(.*)$/
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
---- footer
