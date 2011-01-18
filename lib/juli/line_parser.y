# Text *line* parser for Juli format.
class Juli::LineParser
  options no_result_var

rule
  line
    : elements            { @root = val[0] }

  elements
    : /* none */          { LineAbsyn::ArrayNode.new }
    | elements element    { val[0].add(val[1]) }

  element
    : STRING              { LineAbsyn::StringNode.new(val[0]) }
    | WIKINAME            { LineAbsyn::WikiName.new(val[0]) }
    | TAG                 { LineAbsyn::StringNode.new(val[0]) }
end
---- header
module Juli::LineAbsyn
  class Node
    def accept(visitor)
      visitor.visit_node(self)
    end
  end
  
  class StringNode < Node
    attr_accessor :str
  
    def initialize(str)
      @str = str
    end
  
    def accept(visitor)
      visitor.visit_string(self)
    end
  end

  class WikiName < StringNode
    def accept(visitor)
      visitor.visit_wikiname(self)
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

  # define Visitor default actions
  class Visitor
    def visit_node(n); end

    def visit_array(n)
      for n in n.array do
        n.accept(self)
      end
    end

    def visit_string(n); end
    def visit_wikiname(n); end
  end

  # visitor for debug
  class DebugVisitor < Visitor
    attr_reader :array

    def initialize
      @array = []
    end

    def visit_string(n)
      @array << n.str
    end

    def visit_wikiname(n)
      @array << sprintf("W:%s", n.str)
    end
  end
end

---- inner
  # parse one line and return absyn tree for the line
  def parse(line, wikinames)
    @remain     = line
    @wikinames  = wikinames
    yyparse self, :scan
    @root
  end

private
  # Wikiname scanning algorithm is as follows:
  #
  # 1. input: [..............................................................]
  # 2. scan longest wikiname in wikiname-dictionary:
  #           [<---heading_remain---->LONGEST_WIKINAME<---trailing_remain--->]
  # 3. for remaining in head & trail, do 2. above recursively
  def scan(&block)
    scan_r(@remain, &block)
    yield false, nil
  end

  # recursive scan
  def scan_r(str, &block)
    for w in @wikinames do
      case str
      # to escape wikiname string in tag, tag is prior than wikiname
      when /\A([^<]*)(<[^>]*>)(.*)\z/m
        scan_r($1, &block)
        yield :TAG, $2
        scan_r($3, &block)
        return
      when /\A(.*)#{w}(.*)\z/m
        scan_r($1, &block)
        yield :WIKINAME, w
        scan_r($2, &block)
        return
      end
    end
    yield :STRING, str
  end

---- footer
