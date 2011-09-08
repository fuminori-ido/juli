# Text parser for Juli format.
class Juli::Parser
  options no_result_var

rule
  # Racc action returns absyn node to build absyn-tree, while
  text
    : blocks                    { @root = val[0] }

  blocks
    : /* none */                { Intermediate::ArrayNode.new(0) }
    | blocks block              { val[0].add(val[1]) }

  block
    : textblock                 { Intermediate::StrNode.new(val[0], 0) }
    | verbatim                  { Intermediate::StrNode.new(val[0], 2) }
    | '(' headlines ')'         { val[1] }
    | '(' unordered_list ')'    { val[1] }
    | WHITELINE                 { Intermediate::WhiteLine.new }

  textblock
    : STRING
    | textblock STRING          { val[0] + val[1] }

  verbatim
    : '(' textblock ')'         { val[1] }

  # '(' ... ')' at headlines syntax above 'block' definition is to let
  # racc parse headlines with *level* correctly.
  # It's the same as 'if ... elsif ... elsif ... end' in Ada, Eiffel, and Ruby.
  headlines
    : headline                  {
                h = Intermediate::ArrayNode.new(0)
                h.add(val[0])
              }
    | headlines headline        { val[0].add(val[1]) }

  headline
    : H STRING blocks {
                h = Intermediate::HeaderNode.new(val[0], val[1])
                h.add(val[2])
              }

  unordered_list
    : list_item {
                l = Intermediate::UnorderedList.new(0)
                l.add(val[0])
              }
    | unordered_list list_item { val[0].add(val[1]) }

  list_item
    : UNORDERED_LIST_ITEM   { Intermediate::UnorderedListItem.new(*val[0]) }
    | '(' blocks ')'        { val[1] }
end

---- header
require 'juli/wiki'

---- inner
  require 'erb'
  require 'juli/visitor'

  # keep nest level; will be used to yield ')'
  #
  # This is used for both headline level and list nesting.
  class NestStack
    class InvalidIndentOrder < StandardError; end

    def initialize
      @stack  = []
      @curr   = 0
    end

    # action on '('
    def push(length)
      if @stack.last && length <= @stack.last
        raise InvalidIndentOrder, "length(#{length}) <= top(#{@stack.last})"
      end
      @stack << length
      @curr = length
    end

    # current level of nest
    def curr
      @curr
    end

    # action on ')'
    #
    # go up nest until length meets.  Block (mainly for ')') is called
    # on each pop
    def pop(length, &block)
      if @stack.last && length < @stack.last
        @stack.pop
        if block_given?
          yield
        end
        self.pop(length, &block)
      else
        @curr = length
      end
    end

    def flush(&block)
      pop(0, &block)
    end
  end

  # parse one file, build Intermediate tree, then generate HTML
  def parse(in_file, visitor)
@yydebug = true

    @indent_stack = NestStack.new
    @header_stack = NestStack.new
    @in_file      = in_file
    File.open(in_file) do |io|
      @in_io = io
      yyparse self, :scan
    end
    visitor.run_file(in_file, @root)
  end

  # return intermediate tree
  def tree
    @tree.root
  end

private
  class ScanError < Exception; end

  def scan(&block)
    @src_line = 0
    while line = @in_io.gets do
      @src_line += 1
      case line
      when /^\s*$/
        indent_or_dedent(0, &block)
        yield :WHITELINE, nil
      when /^(={1,6})\s+(.*)$/
        header_nest($1.length, &block)
        yield :H,       $1.length
        yield :STRING,  $2
=begin
      when /^(\s*)(\d+\.\s+)(.*)$/
        yield :ORDERED_LIST_ITEM, [$1.length + $2.length, $3 + "\n"]
=end
      when /^(\s*)(\*\s+)(.*)$/
        indent_or_dedent($1.length, &block)
        yield :UNORDERED_LIST_ITEM, [$1.length + $2.length, $3 + "\n"]
=begin
      when /^(\S.*)::\s*$/
        yield :LONG_DT, $1
      when /^(\S.*)::\s+(.*)$/
        yield :DT, $1
        yield :STRING, $2
=end
      when /^(\s*)(.*)$/
        indent_or_dedent($1.length, &block)
       #yield :LEVEL,   $1.length
        yield :STRING,  $2 + "\n"
      else
        raise ScanError
      end
    end
    indent_or_dedent(0, &block)
    header_nest(0, &block)
    yield false, nil
  end

  def on_error(et, ev, values)
    File.open(@in_file) do |io|
      line = 0
      while line_str = io.gets do
        if @src_line == line
          raise ParseError,
                sprintf("Juli syntax error\n%04d: %s\n", @src_line+1, line_str)
        end
        line += 1
      end
    end
    raise ParseError, sprintf("Juli syntax error at line %d\n", @src_line + 1)
  end

  # calculate indent level and yield '(' or ')' correctly
  def indent_or_dedent(length, &block)
    if @indent_stack.curr < length
      @indent_stack.push(length)
      yield '(', nil
    elsif @indent_stack.curr > length
      @indent_stack.pop(length) do
        yield ')', nil
      end
    end
  end

  # calculate header level and yield '(' or ')' correctly
  def header_nest(length, &block)
    # at header level change, flush indent_stack
    @indent_stack.flush{yield ')', nil}

    if @header_stack.curr < length
      @header_stack.push(length)
      yield '(', nil
    elsif @header_stack.curr > length
      @header_stack.pop(length) do
        yield ')', nil
      end
    end
  end
---- footer
