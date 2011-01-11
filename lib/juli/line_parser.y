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
end
---- header
module LineAbsyn
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
    attr_accessor :str
  
    def initialize(str)
      @str = str
    end
  
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
  
  class Visitor
    def visit_node(n); end
    def visit_array(n); end
    def visit_string(n); end
    def visit_wikiname(n); end
  end
end

---- inner
  # parse one line, build absyn tree
  def parse(line)
    @remain     = line
    @wikinames  = Juli::Wiki.gather_wikiname
    yyparse self, :scan
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
  end

  # recursive scan
  def scan_r(str, &block)
    for w in @wikiname do
      if str =~ /^(.*)(#{w})(.*)$/
        scan_r($1, &block)
        yield :WIKINAME, $2
        scan_r($3, &block)
      end
    end
    yield :STRING, str
  end
---- footer
