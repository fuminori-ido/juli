# Text parser for Juli format.
class Juli::Parser
  options no_result_var

rule
  # Racc action returns absyn node to build absyn-tree
  text
    : blocks                    { @root = val[0] }

  blocks
    : /* none */                { Intermediate::ArrayNode.new(0) }
    | blocks block              { val[0].add(val[1]) }

  block
    : textblock                 { Intermediate::StrNode.new(val[0], 0) }
    | verbatim                  { Intermediate::StrNode.new(val[0], 2) }
    | headline_block
    | unordered_list_block
    | WHITELINE                 { Intermediate::WhiteLine.new }

  textblock
    : STRING
    | textblock STRING          { val[0] + val[1] }

  verbatim
    : '(' textblock ')'         { val[1] }

  # '{' ... '}' at headline_block syntax is to let
  # racc parse headlines with *level* correctly.
  # It's the same as 'if ... elsif ... elsif ... end' in Ada, Eiffel, and Ruby.
  headline_block
    : '{' headlines '}'         { val[1] }
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

  unordered_list_block
    : '(' unordered_list ')'    { val[1] }
  unordered_list
    : list_item {
                l = Intermediate::UnorderedList.new(0)
                l.add(val[0])
              }
    | unordered_list list_item  { val[0].add(val[1]) }
    | unordered_list block      { val[0].add(val[1]) }

  list_item
    : UNORDERED_LIST_ITEM   { Intermediate::UnorderedListItem.new(*val[0]) }
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
    class InvalidOrder < StandardError; end

    def initialize
      @stack    = []
      @baseline = 0
    end

    # action on '('
    def push(length)
      if @stack.last && length <= @stack.last
        raise InvalidOrder, "length(#{length}) <= top(#{@stack.last})"
      end
      @stack << length
      @baseline = length
    end

    # current baseline
    def baseline
      @baseline
    end

    # action on ')'
    #
    # go up nest until length meets.  Block (mainly for ')') is called
    # on each pop
    def pop(length, &block)
      if @stack.last && length < @stack.last
        @stack.pop
        yield if block_given?
        self.pop(length, &block)
      else
        @baseline = length
      end
    end

    def flush(&block)
      while @stack.last do
        yield if block_given?
        @stack.pop
      end
      @baseline = 0
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
        indent_or_dedent($1.length + $2.length, &block)
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
    @indent_stack.flush{ yield ')', nil }
    @header_stack.flush{ yield '}', nil }
    yield false, nil
  end

  def on_error(et, ev, values)
    File.open(@in_file) do |io|
      line = 0
      while line_str = io.gets do
        line += 1
        if @src_line == line
          raise ParseError,
                sprintf("Juli syntax error\n%04d: %s\n", @src_line, line_str)
        end
      end
    end
    raise ParseError, sprintf("Juli syntax error at line %d\n", @src_line)
  end

  # calculate indent level and yield '(' or ')' correctly
  def indent_or_dedent(length, &block)
    if @indent_stack.baseline < length
      @indent_stack.push(length)
      yield '(', nil
    elsif @indent_stack.baseline > length
      @indent_stack.pop(length) do
        yield ')', nil
      end
    end
  end

  # calculate header level and yield '(' or ')' correctly
  def header_nest(length, &block)
    # at header level change, flush indent_stack
    @indent_stack.flush{ yield ')', nil }

    if @header_stack.baseline < length
      @header_stack.push(length)
      yield '{', nil
    elsif @header_stack.baseline > length
      @header_stack.pop(length) do
        yield '}', nil
      end
    end
  end
---- footer
