# Text parser for Juli format.
class Juli::Parser
  options no_result_var

rule
  # Racc action returns absyn node to build absyn-tree
  text
    : blocks                    { @root = val[0] }

  blocks
    : /* none */                { Absyn::ArrayNode.new }
    | blocks block              { val[0].add(val[1]) if val[1]; val[0] }

  block
    : textblock                 { Absyn::StrNode.new(val[0]) }
    | '(' textblock ')'         { Absyn::Verbatim.new(val[1]) }
    | '{' chapters '}'          { val[1] }
    | '(' ulist ')'             { val[1] }
    | '(' olist ')'             { val[1] }
    | cdlist
    | dlist
    | WHITELINE                 { nil }

  textblock
    : STRING
    | textblock STRING          { val[0] + val[1] }

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
                h = Absyn::ArrayNode.new
                h.add(val[0])
              }
    | chapters chapter { val[0].add(val[1]) }
  chapter
    : H STRING blocks { Absyn::Chapter.new(val[0], val[1], val[2]) }

  # unordered list
  ulist
    : ulist_item {
                l = Absyn::UnorderedList.new
                l.add(val[0])
              }
    | ulist ulist_item  { val[0].add(val[1]) }
  ulist_item
    : '*' blocks        { val[1] }

  # ordered list
  olist
    : olist_item {
                l = Absyn::OrderedList.new
                l.add(val[0])
              }
    | olist olist_item  { val[0].add(val[1]) }
  olist_item
    : '#' blocks        { val[1] }

  # compact dictionary list
  cdlist
    : cdlist_item         { l = Absyn::CompactDictionaryList.new
                            l.add(val[0])
                          }
    | cdlist cdlist_item  { val[0].add(val[1]) }
  cdlist_item
    : CDT STRING          { Absyn::CompactDictionaryListItem.new(
                                val[0], val[1]) }

  # dictionary list
  dlist
    : dlist_item        { l = Absyn::DictionaryList.new; l.add(val[0]) }
    | dlist dlist_item  { val[0].add(val[1]) }
  dlist_item
    : DT '(' textblock ')'  { Absyn::DictionaryListItem.new(val[0], val[2]) }
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
      if @stack.last && @stack.last >= length
        raise InvalidOrder, "top(#{@stack.last}) >= length(#{length})"
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
    # If length==nil, pop just 1 level up
    def pop(length = nil, &block)
      if length
        if @stack.last && @stack.last > length
          @stack.pop
          yield if block_given?
          self.pop(length, &block)
        else
          @baseline = @stack.last ? length : 0
        end
      else
        if @stack.last
          @stack.pop
          yield if block_given?
          @baseline = @stack.last || 0
        end
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

  # parse one file, build Absyn tree, then generate HTML
  def parse(in_file, visitor)
    @yydebug      = true          if ENV['YYDEBUG']
    @indent_stack = NestStack.new
    @header_stack = NestStack.new

    @in_verbatim  = false
    @in_file      = in_file
    File.open(in_file) do |io|
      @in_io = io
      yyparse self, :scan
    end
    visitor.run_file(in_file, @root)
  end

  # return absyn tree
  def tree
    @root
  end

private
  class ScanError < Exception; end

  def scan(&block)
    @src_line = 0
    while line = @in_io.gets do
      debug("@in_verbatim = #{@in_verbatim.inspect}")
      @src_line += 1
      case line
      when /^\s*$/
        if @in_verbatim
          yield [:STRING, "\n"]
        else
          indent_or_dedent(0, &block)
          yield [:WHITELINE, nil]
        end
      when /^(={1,6})\s+(.*)$/
        header_nest($1.length, &block)
        yield [:H,       $1.length]
        yield [:STRING,  $2]
      when /^(\s*)(\d+\.\s+)(.*)$/
        on_list_item(line, '#', $1.length, $2.length, $3, &block)
      when /^(\s*)(\*\s+)(.*)$/
        on_list_item(line, '*', $1.length, $2.length, $3, &block)
      when /^(\S.*)::\s*$/
        indent_or_dedent(0, &block)
        yield [:DT, $1]
      when /^(\S.*)::\s+(.*)$/
        # since compact dictionary list is not nested, indent control is
        # not necessary.
        yield [:CDT, $1]
        yield [:STRING, $2]
      when /^(\s*)(.*)$/
        length = $1.length
        if @in_verbatim
          debug_indent('in_verbatim', length)
          if @indent_stack.baseline > length     # end of verbatim
            dedent(length, &block)
            end_of_verbatim(length, &block)
          else
            # do nothing (continue of verbatim)
          end
        else
          debug_indent('NOTverbatim', length)
          if @indent_stack.baseline < length        # begin verbatim
            indent(length, &block)
            @in_verbatim = true
          elsif @indent_stack.baseline > length     # end of nest ')'
            dedent(length, &block)
          end
        end
        yield [:STRING,
               (@in_verbatim ?
                   ' ' * (length - @indent_stack.baseline) :
                   '') + $2 + "\n"]
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
                sprintf("%s: Juli syntax error\n%04d: %s\n",
                    @in_file,
                    @src_line,
                    line_str)
        end
      end
    end
    raise ParseError, sprintf("Juli syntax error at line %d\n", @src_line)
  end

  def on_list_item(line, token, length1, length2, str, &block)
    length  = length1 + length2
    debug_indent("list item('#{token}')", length)
    if @in_verbatim
      if @indent_stack.baseline <= length1
        yield [:STRING,  line]
      else
        # after verbatim, dedent just 1-level because there is no
        # deeper nest in verbatim
        dedent(&block)
        @in_verbatim = false
        indent_or_dedent_on_non_verbatim(length, &block)
        yield [token, nil]
        yield [:STRING, str + "\n"]
      end
    else
      indent_or_dedent(length, &block)
      yield [token, nil]
      yield [:STRING, str + "\n"]
    end
  end

  # calculate indent level and yield '(' or ')' correctly
  def indent_or_dedent(length, &block)
    if @in_verbatim
      debug_indent('in_verbatim', length)
      if @indent_stack.baseline > length    # end of verbatim
        dedent(length, &block)
        @in_verbatim = false
      end
    else
      indent_or_dedent_on_non_verbatim(length, &block)
    end
  end

  def indent_or_dedent_on_non_verbatim(length, &block)
    debug_indent('NOTverbatim', length)
    if @indent_stack.baseline < length    # begin verbatim
      indent(length, &block)
    elsif @indent_stack.baseline > length
      dedent(length, &block)
    end
  end

  def indent(length, &block)
    @indent_stack.push(length)
    yield ['(', nil]
  end

  def dedent(length=nil, &block)
    @indent_stack.pop(length) do
      yield [')', nil]
    end
  end

  # Special case: 'continued string line just after verbatim, but its
  # offset length is less than baseline'.  For example, this happens
  # at test/repo/t022-2.txt 2nd line.
  #
  # Treat as:
  #
  # 1. end of verbatim
  # 2. begin new verbatim if baseline < length, else
  #    begin simple string
  # 
  def end_of_verbatim(length, &block)
    debug_indent('end_of_verbatim', length)
    if @indent_stack.baseline < length            # begin verbatim
      indent(length, &block)
      @in_verbatim = true
    else
      @in_verbatim = false
    end
  end

  # calculate header level and yield '(' or ')' correctly
  def header_nest(length, &block)
    # at header level change, flush indent_stack
    @indent_stack.flush{ yield [')', nil] }
    @in_verbatim = false

    if @header_stack.baseline < length
      @header_stack.push(length)
      yield ['{', nil]
    elsif @header_stack.baseline > length
      @header_stack.pop(length) do
        yield ['}', nil]
      end
    end
  end

  # print indent info on debug
  def debug_indent(key, length)
    debug(sprintf(
        "indent(%s): @indent_stack(%s,%d), length=%d",
        key,
        @indent_stack.status,
        @indent_stack.baseline,
        length))
  end

  # general debug method
  def debug(str)
    @racc_debug_out.print(str, "\n") if @yydebug
  end
---- footer
