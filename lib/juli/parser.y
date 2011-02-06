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

  #   |   1. HelloWorld
  #    <-><-><-----------
  #             str
  #       offset
  #    level
  class OrderedListItem < Node
    attr_accessor :level, :offset, :str
  
    def initialize(level, offset, str)
      @level  = level
      @offset = offset
      @str    = str
    end
  
    def accept(visitor)
      visitor.visit_ordered_list_item(self)
    end
  end

  #   |   *  HelloWorld
  #    <-><-><-----------
  #             str
  #       offset
  #    level
  class UnorderedListItem < Node
    attr_accessor :level, :offset, :str
  
    def initialize(level, offset, str)
      @level  = level
      @offset = offset
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
# === Baseline
# Same concept as rdtools.  It is indent or offset from beginnig of a line.
# When:
# list level + offset == string level:  continue of list
# list level + offset <  string level:  quote in the list
# list level + offset >  string level:  end of list and begin quote
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

    # While level is kept in @list, offset is kept here because:
    # 1. offset is only necessary on continued list.
    # 1. level is necessary to calculate node-depth.
    @offset     = 0
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
    if @list && @list.level + @offset == n.level
                                      # continue of list?
      @list.array.last.str += ' ' + n.str
      # At this case, baseline *DOESN'T* become n.level.  It keeps
      # @list's baseline.
    elsif n.level > @baseline         # beginning of quote
      str_block_break
      @str_block = n.str
      @baseline = n.level
    elsif n.level == @baseline        # same baseline
      # if same baseline but previous is array, then it's list_break
      if @list
        list_break
      end
      @str_block += n.str

    else                              # end of quote -> flush it
      # @str_block may contain only "\n" when following case:
      #
      #   |1. hello
      #   |   a
      #   |               <-- here!
      #   |next...
      #
      # This should be ignored:
      if @str_block !~ /\A\s*\Z/m
        @array.add(Intermediate::QuoteNode.new(@str_block))
      end
      @str_block = n.str              # beginning of new str_block
      @baseline = n.level
    end
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
    if @str_block !~ /\A\s*\z/m
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
      @list.add(list_item_class.new(n.str))

    # when @list points to upper or nil and parses lower(=nested) list,
    # build new list node under the upper and shift @list to it:
    elsif !@list || @list.level < n.level
      new_list  = list_class.new(n.level)
      @array.add(new_list)
      new_list.add(list_item_class.new(n.str))
      @list = @array = new_list

    # when @list points to lower and parses upper, find parent,
    # build new node under it, and shift @list to it:
    else
      parent_list = @list.find_upper_or_equal(n.level)
      parent_list.add(list_item_class.new(n.str))
      @list = @array = parent_list
    end
    @offset = n.offset
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
        yield :ORDERED_LIST_ITEM, [$1.length, $2.length, $3]
      when /^(\s*)(\*\s+)(.*)$/
        yield :UNORDERED_LIST_ITEM, [$1.length, $2.length, $3]
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
---- footer
