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
    | URL                 { LineAbsyn::Url.new(val[0]) }
    | MACRO               { LineAbsyn::Macro.new(val[0][0], val[0][1]) }
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

  class Url < StringNode
    def accept(visitor)
      visitor.visit_url(self)
    end
  end

  class Macro < Node
    attr_accessor :name, :rest

    def initialize(name, rest)
      @name = name
      @rest = rest
    end
  
    def accept(visitor)
      visitor.visit_macro(self)
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
    def visit_url(n); end
    def visit_macro(n); end
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

    def visit_url(n)
      @array << sprintf("U:%s", n.str)
    end

    def visit_macro(n)
      @array << sprintf("M:%s:%s", n.name, n.rest)
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
    yield [false, nil]
  end

  URL = '(https?:|mailto:|ftp:)\S+'

  # recursive scan
  def scan_r(str, &block)
    for w in @wikinames do
      case str
      # to escape wikiname string in <a>...</a>, it is prior to wikiname
      #
      # If word in <a ...>word</a> tag is a wikiname, it would be produced to
      # <a ...><a ...>word</a></a> because it is a wikiname.  In order to
      # avoid this, two ways can be considered:
      #
      # 1. introduce escape notation.  e.g. rdoc \word
      # 2. introduce special inline escape logic just for <a>...</a>
      #
      # I choose latter for simple usage.
      when /\A([^<]*)(<a[^>]*>[^<]*<\/a>)(.*)\z/m
        scan_r($1, &block)
        yield [:STRING, $2]   # <a>...</a> is just string even wikiname be there
        scan_r($3, &block)
        return

      # to escape wikiname string in HTML tag, it is prior to wikiname
      when /\A([^<]*)(<[^>]*>)(.*)\z/m
        scan_r($1, &block)
        yield [:STRING, $2]   # <a>...</a> is just string even wikiname be there
        scan_r($3, &block)
        return

      # escape of escape: \\{ -> \{
      when /\A([^\\]*)\\\\\{(.*)\z/m
        scan_r($1, &block)
        yield [:STRING, '\\{']
        scan_r($2, &block)
        return

      # explicit escape by \{!...}
      when /\A([^\\]*)\\\{!([^}]+)\}(.*)\z/m
        scan_r($1, &block)
        yield [:STRING, $2]
        scan_r($3, &block)
        return

      # macro \{command rest}
      when /\A([^\\]*)\\\{(\w+)\s*([^}]*)\}(.*)\z/m
        scan_r($1, &block)
        yield [:MACRO, [$2, $3]]
        scan_r($4, &block)
        return
      
      # URL is piror to wikiname
      when /\A(|.*\s+)(#{URL})(.*)\z/m
        scan_r($1, &block)
        yield [:URL, $2]
        scan_r($4, &block)    # not $3 since URL itself has (...)
        return

      when /\A(.*)#{w}(.*)\z/m
        scan_r($1, &block)
        yield [:WIKINAME, w]
        scan_r($2, &block)
        return
      end
    end
    yield [:STRING, str]
  end

---- footer
