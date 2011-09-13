# Text parser for Juli format.
class Juli::Parser
  options no_result_var

rule
  # Racc action returns absyn node to build absyn-tree
  text
    : blocks                    { @root = val[0] }

  blocks
    : /* none */                { Intermediate::ArrayNode.new }
    | blocks block              { val[0].add(val[1]) if val[1]; val[0] }

  block
    : textblock                 { Intermediate::StrNode.new(val[0]) }
    | verbatim                  { Intermediate::Verbatim.new(val[0]) }
    | '{' chapters '}'          { val[1] }
    | '(' ulist ')'             { val[1] }
    | '(' olist ')'             { val[1] }
    | WHITELINE                 { nil }

  textblock
    : STRING
    | textblock STRING          { val[0] + val[1] }

  verbatim
    : '(' textblock ')'         { val[1] }

  # chapters are list of chapter at the same level,
  # and chapter is header + blocks.
  #
  # Where, chapter here refers both chapter and/or section in
  # usual meanings since (again) it contains header + blocks.
  # 
  # '{' ... '}' at chapters syntax is to let
  # racc parse headlines with *level* correctly.
  # It's the same as 'if ... elsif ... elsif ... end' in Ada, Eiffel, and Ruby.
  chapters
    : chapter {
                h = Intermediate::ArrayNode.new
                h.add(val[0])
              }
    | chapters chapter { val[0].add(val[1]) }
  chapter
    : H STRING blocks { Intermediate::Chapter.new(val[0], val[1], val[2]) }

  # unordered list
  ulist
    : ulist_item {
                l = Intermediate::UnorderedList.new
                l.add(val[0])
              }
    | ulist ulist_item  { val[0].add(val[1]) }
  ulist_item
    : '*' blocks        { val[1] }

  # ordered list
  olist
    : olist_item {
                l = Intermediate::OrderedList.new
                l.add(val[0])
              }
    | olist olist_item  { val[0].add(val[1]) }
  olist_item
    : '#' blocks        { val[1] }
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
       #@baseline = @stack.last ? length : 0
      end
    end

    def flush(&block)
      while @stack.last do
        yield if block_given?
        @stack.pop
      end
      @baseline = 0
    end

    # for debug
    def status
      @stack.inspect
    end
  end

  # parse one file, build Intermediate tree, then generate HTML
  def parse(in_file, visitor)
    @yydebug      = true          if ENV['YYDEBUG']
    @indent_stack = NestStack.new
    @header_stack = NestStack.new
    @indent_level = nil
    @in_file      = in_file
    File.open(in_file) do |io|
      @in_io = io
      yyparse self, :scan
    end
    visitor.run_file(in_file, @root)
  end

  # return intermediate tree
  def tree
    @root
  end

private
  class ScanError < Exception; end

  def scan(&block)
    @src_line = 0
    while line = @in_io.gets do
      debug("@indent_level = #{@indent_level.inspect}")
      @src_line += 1
      case line
      when /^\s*$/
        indent_or_dedent(0, &block)
        yield [:WHITELINE, nil]
      when /^(={1,6})\s+(.*)$/
        header_nest($1.length, &block)
        yield [:H,       $1.length]
        yield [:STRING,  $2]
      when /^(\s*)(\d+\.\s+)(.*)$/
        length = $1.length + $2.length
        if in_verbatim && @indent_stack.baseline <= length
          yield [:STRING,  line]
        else
          indent_or_dedent(length, &block)
          yield ['#', nil]
          yield [:STRING, $3 + "\n"]
        end
      when /^(\s*)(\*\s+)(.*)$/
        length = $1.length + $2.length
        if in_verbatim && @indent_stack.baseline <= length
          yield [:STRING,  line]
        else
          indent_or_dedent(length, &block)
          yield ['*', nil]
          yield [:STRING, $3 + "\n"]
        end
=begin
      when /^(\S.*)::\s*$/
        yield [:LONG_DT, $1]
      when /^(\S.*)::\s+(.*)$/
        yield [:DT, $1]
        yield [:STRING, $2]
=end
      when /^(\s*)(.*)$/
        indent_length = $1.length
        if !in_verbatim && @indent_stack.baseline < indent_length
          indent_or_dedent(indent_length, &block)
          @indent_level = indent_length
        else
          indent_or_dedent(indent_length, &block)
        end
        indent_or_dedent(indent_length, &block)
        yield [:STRING,  $2 + "\n"]
      else
        raise ScanError
      end
    end
    @indent_stack.flush{ yield [')', nil] }
    @header_stack.flush{ yield ['}', nil] }
    yield [false, nil]
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

  def in_verbatim
    @indent_level != nil
  end

  # calculate indent level and yield '(' or ')' correctly
  def indent_or_dedent(length, &block)
    if in_verbatim
      debug_indent('in_verbatim', length)
      if @indent_stack.baseline > length    # end of verbatim
        @indent_level = nil
        @indent_stack.pop(length) do
          yield [')', nil]
        end
      end
    else
      debug_indent('NOTverbatim', length)
      if @indent_stack.baseline < length    # begin verbatim
        @indent_stack.push(length)
        yield ['(', nil]
      elsif @indent_stack.baseline > length
        @indent_stack.pop(length) do
          yield [')', nil]
        end
      end
    end
  end

  # calculate header level and yield '(' or ')' correctly
  def header_nest(length, &block)
    # at header level change, flush indent_stack
    @indent_stack.flush{ yield [')', nil] }

    if @header_stack.baseline < length
      @header_stack.push(length)
      yield ['{', nil]
    elsif @header_stack.baseline > length
      @header_stack.pop(length) do
        yield ['}', nil]
      end
    end
  end

  def debug_indent(key, length)
    debug(sprintf(
        "indent_or_dedent() %s: @indent_stack(%s,%d), length=%d",
        key,
        @indent_stack.status,
        @indent_stack.baseline,
        length))
  end

  def debug(str)
    @racc_debug_out.print(str, "\n") if @yydebug
  end
---- footer
