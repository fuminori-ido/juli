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
    : elements          { @root = val[0] }

  elements
    : /* none */        { Absyn::ArrayNode.new }
    | elements element  { val[0].add(val[1]) }

  element
    : H STRING          { Absyn::HeaderNode.new(val[0], val[1]) }
    | ANY
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
    attr_accessor :level, :name
  
    def initialize(level, name)
      @level  = level
      @name   = name
    end
  
    def accept(visitor)
      visitor.visit_header(self)
    end
  end
  
  class Visitor
    def visit_node(n); end
    def visit_array(n); end
    def visit_default(n); end
    def visit_header(n); end
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
    @root = @curr_node = Intermediate::HeaderNode.new(0, '(root)')
  end

  def root
    @root
  end

  def visit_array(n)
    for child in n.array do
      case child
      when Absyn::DefaultNode
        @curr_node.add(Intermediate::DefaultNode.new(child.str))
      else
        build_subtree(child)
      end
    end
  end

private
  def build_subtree(absyn_header)
    # When @curr_node points to upper (e.g. root) and parse level-1 as
    # follows, build new node under the upper and shift @curr_node to it:
    #
    #   (root)          - @curr_node
    #     test
    #     = NAME        - we are here!
    #     ...
    #
    if @curr_node.level < absyn_header.level
      new_node = Intermediate::HeaderNode.new(absyn_header)
      @curr_node.add(new_node)
      @curr_node = new_node

    # When @curr_node points to lower level (e.g. 'Option' below)
    # and parses 'SEE ALSO' (level=1) as follows, find parent, 
    # build new node under it, and shift @curr_node to the new node:
    #
    #   ...
    #   === Option      - @curr_node
    #   ...
    #   = SEE ALSO      - we are here!
    else
      new_node = Intermediate::HeaderNode.new(absyn_header)
      @curr_node.find_upper(absyn_header.level).add(new_node)
      @curr_node = new_node
    end
  end
end

  require 'erb'
  require 'juli/visitor'

  # parse one file, build Intermediate tree, then generate HTML
  def parse(in_file)
    File.open(in_file) do |io|
      @in_io = io
      yyparse self, :scan
    end
    tree = TreeBuilder.new
    @root.accept(tree)
    Visitor::Html.new.run(in_file, tree.root)
   #Visitor::PrintTree.new.run(in_file, tree.root)
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
      when /^=\s+(.*$)$/
        header(1, $1, &block)
      when /^==\s+(.*$)$/
        header(2, $1, &block)
      when /^===\s+(.*$)$/
        header(3, $1, &block)
      when /^====\s+(.*$)$/
        header(4, $1, &block)
      when /^=====\s+(.*$)$/
        header(5, $1, &block)
      when /^======+\s+(.*$)$/
        header(6, $1, &block)
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
    block_break
    yield :H,       level
    yield :STRING,  string
  end

---- footer
