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
    # scan current level and gather DefaultNode into one
    str = ''
    for child in n.array do
      case child
      when Absyn::DefaultNode
        str += child.str
      else
        if str != ''
          @curr_node.add(Intermediate::DefaultNode.new(str))
          str = ''
        end
        build_subtree(child)
      end
    end
    if str != ''
      @curr_node.add(Intermediate::DefaultNode.new(str))
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
  end

private
  def scan
    while line = @in_io.gets do
      case line
      when /^\s*$/
        # skip empty line
      when /^=\s+(.*$)$/
        yield :H, 1; yield :STRING, $1
      when /^==\s+(.*$)$/
        yield :H, 2; yield :STRING, $1
      when /^===\s+(.*$)$/
        yield :H, 3; yield :STRING, $1
      when /^====\s+(.*$)$/
        yield :H, 4; yield :STRING, $1
      when /^=====\s+(.*$)$/
        yield :H, 5; yield :STRING, $1
      when /^======+\s+(.*$)$/
        yield :H, 6; yield :STRING, $1
      else
        yield :ANY, line
      end
    end
    yield false, nil
  end

---- footer
