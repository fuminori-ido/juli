require 'fileutils'
require 'pathname'
require 'juli/util'
require 'juli/line_parser.tab'
require 'juli/absyn'

module Juli::Visitor
  # This visits Absyn tree and generates HTML
  #
  # Text files under juli-repository must have '.txt' extention.
  #
  # === OPTIONS
  # -f::            force update
  # -t template::   specify template
  class Html < Juli::Absyn::Visitor
    require 'juli/visitor/html/tag_helper'
    require 'juli/visitor/html/helper'
    require 'juli/macro'

    include Juli::Util
    include Juli::Visitor::Html::TagHelper
    include Juli::Visitor::Html::Helper

    # assign DOM id on header node.
    #
    # IdAssigner should be executed before running Html visitor since
    # ContentsDrawer also refers DOM id.  That is the reason why DOM id
    # assignment is isolated from Html visitor.
    class IdAssigner < Juli::Absyn::Visitor
      def initialize(opts={})
        super
        @uniq_id_seed   = 0
      end
    
      def visit_chapter(n)
        n.dom_id = uniq_id(n.level)
        n.blocks.accept(self)
      end
  
      def run(in_file, root)
        root.accept(self)
      end
  
    private
      # generate uniq_id, and track it for each level to be used later
      def uniq_id(level)
        @uniq_id_seed += 1
        result = sprintf("j%05d", @uniq_id_seed)
        result
      end
    end
  
    # visits a line of document text and generate:
    #
    # * hyperlink on wikiname.
    # * hyperlink on url like http://...
    # * macro result
    class HtmlLine < Juli::LineAbsyn::Visitor
      include Juli::Util
      include TagHelper

      def initialize(macros)
        @_macros = macros
      end

      def visit_array(n)
        n.array.inject('') do |result, n|
          result += n.accept(self)
        end
      end
  
      def visit_string(n)
        n.str
      end
  
      def visit_wikiname(n)
        decoded = Juli::Wiki.decode(n.str)
        content_tag(:a, decoded, :class=>'wiki', :href=>decoded + conf['ext'])
      end
  
      def visit_url(n)
        content_tag(:a, n.str, :class=>'url', :href=>n.str)
      end

      def visit_macro(n)
        if macro = @_macros[camelize(n.name).to_sym]
          macro.run(*n.rest.split(' '))
        else
          s = "juli ERR: UNKNOWN macro name: '#{n.name}'"
          STDERR.print s, "\n"
          s
        end
      end
    end

    # Html sepecific initialization does:
    #
    # 1. create output_top.
    # 1. copy *.js, *.css files to output_top/
    #
    # NOTE: this is executed every juli(1) run with -g html option
    # (usually 99% is so), so be careful to avoid multiple initialization.
    def initialize(opts={})
      super

      # files here will not be deleted even if corresponding *.txt file
      # doesn't exist.
      @exception = {
        'sitemap' + conf['ext']       => 1,
        'recent_update' + conf['ext'] => 1,
      }

      register_helper
      register_macro
      @html_line_visitor  = HtmlLine.new(@_macros)

      if !File.directory?(conf['output_top'])
        FileUtils.mkdir_p(conf['output_top'])
      end
      copy_to_output_top('prototype.js')
      copy_to_output_top('juli.js')
      copy_to_output_top('juli.css')
    end

    # run in bulk-mode.  In Html visitor, it sync juli-repository and
    # OUTPUT_TOP.
    def run_bulk
      sync
    end

    # visit root to generate:
    #
    # 1st:: HTML body
    # 2nd:: whole HTML by ERB.
    def run_file(in_file, root)
      @header_sequence  = HeaderSequence.new
      IdAssigner.new.run(in_file, root)

      for key, helper in @_helpers do
        helper.on_root(in_file, root, self)
      end
      for macro_symbol, macro in @_macros do
        macro.on_root(in_file, root, self)
      end

      # store to instance var for 'contents' helper
      @root       = root
      title       = File.basename(in_file.gsub(/\.[^.]*$/, ''))
      prototype   = relative_from(in_file, 'prototype.js')
      javascript  = relative_from(in_file, 'juli.js')
      stylesheet  = relative_from(in_file, 'juli.css')
      sitemap     = relative_from(in_file, 'sitemap' + conf['ext'])
      body        = root.accept(self)

      for macro_symbol, macro in @_macros do
        macro.after_root(in_file, root)
      end

      erb         = ERB.new(File.read(template))
      out_path    = out_filename(in_file, @opts[:o])
      mkdir(out_path)
      File.open(out_path, 'w') do |f|
        f.write(erb.result(binding))
      end
      printf("generated:       %s\n", out_path)
    end

    # if str is in list, don't enclose by <p>
    def visit_str(n)
      if n.parent && n.parent.parent &&
          n.parent.parent.is_a?(Juli::Absyn::List)
        str2html(n.str)
      else
        content_tag(:p, paragraph_css) do
          str2html(n.str)
        end
      end
    end

    def visit_verbatim(n)
      # quote; trim last white spaces at generating phase
      content_tag(:blockquote,
          content_tag(:pre, n.str.gsub(/\s+\z/m, '')),
          blockquote_css)
    end
  
    def visit_array(n)
      n.array.inject(''){|result, child|
        result += child.accept(self)
      }
    end

    def visit_chapter(n)
      header_link(n) +
      content_tag(:div, :id=>n.dom_id) do
        n.blocks.accept(self)
      end + "\n"
    end

    def visit_ordered_list(n)
      visit_list(:ol, n)
    end

    def visit_unordered_list(n)
      visit_list(:ul, n)
    end

    def visit_compact_dictionary_list(n)
      content_tag(:table, :class=>'juli_compact_dictionary') do
        n.array.inject('') do |result, child|
          result += child.accept(self)
        end
      end
    end

    def visit_compact_dictionary_list_item(n)
      content_tag(:tr) do
        content_tag(:td, str2html(n.term) + ':', :nowrap=>true) +
        content_tag(:td, str2html(n.str))
      end
    end

    def visit_dictionary_list(n)
      content_tag(:dl, :class=>'juli_dictionary') do
        n.array.inject('') do |result, child|
          result += child.accept(self)
        end
      end
    end

    def visit_dictionary_list_item(n)
      content_tag(:dt, str2html(n.term), dt_css) +
      content_tag(:dd, str2html(n.str),  dd_css)
    end

    def template=(name)
      @template = name
    end

  private
    # Similar to Rails underscore() method.
    #
    # Example: 'A::B::HelperMethod' -> 'helper_method'
    def self.to_method(helper_class)
      Juli::Util::underscore(helper_class.to_s)
    end

    def copy_to_output_top(file)
      src   = File.join(Juli::TEMPLATE_PATH, file)
      dest  = File.join(conf['output_top'], file)
      return if File.exist?(dest) && File.stat(dest).mtime >= File.stat(src).mtime

      FileUtils.cp(src, dest, :preserve=>true)
    end

    # register each XHelper instance in @_helpers hash.
    def register_helper
      @_helpers = {}
      for helper_symbol in Juli::Visitor::Html::Helper.constants do
        next if helper_symbol == :AbstractHelper
        helper_class = Juli::Visitor::Html.module_eval(helper_symbol.to_s)
        helper = helper_class.new
        helper.set_conf_default(conf)
        @_helpers[helper_symbol.to_sym] = helper
      end
    end

    # define helper method 'x' from XHelper class to call
    # @_helpers[:x].run(*args)
    for helper_symbol in Juli::Visitor::Html::Helper.constants do
      next if helper_symbol == :AbstractHelper
      class_eval <<-end_of_dynamic_method, __FILE__, __LINE__ + 1
        def #{to_method(helper_symbol)}(*args)
          @_helpers[:#{helper_symbol}.to_sym].run(*args)
        end
      end_of_dynamic_method
    end


    # create Macro object and register it in @_macros hash.
    #
    # call set_conf_default() to set conf[key] default value for each macro
    def register_macro
      @_macros = {}
      for macro_symbol in Juli::Macro.constants do
        next if macro_symbol == :Base
        macro_class = Juli::Macro.module_eval(macro_symbol.to_s)
        macro = macro_class.new
        macro.set_conf_default(conf)
        @_macros[macro_symbol] = macro
      end
    end

    # synchronize repository and OUTPUT_TOP.
    #
    # * if text file, calls sync_txt()
    # * for others, do rsync(1)
    #
    def sync
      sync_txt
      sync_others
    end

    def sync_others
      Dir.chdir(juli_repo){
        system 'rsync', '-avuzb',
          '--exclude',  '*.txt',
          '--exclude',  'html/',
          '--exclude',  '*~',
          '--exclude',  '.juli/',
          '--exclude',  '.git*',
          '.',  conf['output_top']
      }
    end

    # synchronize text file between juli-repo and OUTPUT_TOP:
    #
    # 1. new file exists, generate it.
    # 1. repo's file timestamp is newer than the one under OUTPUT_TOP, regenerate it.
    # 1. correspondent file of OUTPUT_TOP/.../f doesn't exist in repo
    #    and not in @exception list above, delete it.
    # 1. if -f option is specified, don't check timestamp and always generates.
    #
    def sync_txt
      repo      = {}
      Dir.chdir(juli_repo){
        Dir.glob('**/*.txt'){|f|
          repo[f] = 1
        }
      }

      # When new file exists, generate it.
      # When repo's file timestamp is newer than OUTPUT_TOP, regenerate it.
      for f,v in repo do
        out_file = out_filename(f, @opts[:o])
        if !@opts[:f] &&
           File.exist?(out_file) &&
           File.stat(out_file).mtime >= File.stat(File.join(juli_repo,f)).mtime
          #printf("already updated: %s\n", out_file)
        else
          Juli::Parser.new.parse(f, self)
        end
      end

      # When correspondent file of OUTPUT_TOP/.../f doesn't exist in repo,
      # and not in @exception list above, delete it.
      Dir.chdir(conf['output_top']){
        Dir.glob('**/*' + conf['ext']){|f|
          next if @exception[f]
          in_file = File.join(juli_repo, in_filename(f))
          if !File.exist?(in_file) && !File.exist?(in_file + '.txt')
            FileUtils.rm(f)
            printf("%s is deleted since no correspondent source text.\n", f)
          end
        }
      }
    end

    # draw <hi>... link, where i=2..7
    #
    # NOTE: <h1> is reserved for title.  <h2>, <h3>, ... are used for Juli
    # formatting '=', '==', ...
    def header_link(n)
      id = n.dom_id
      content_tag("h#{n.level + 1}", :id=>header_id(n)) do
        content_tag(:span, :class=>'juli_toggle', :onclick=>"Juli.toggle('#{id}');") do
         #content_tag(:span, '[+] ', :id=>"#{id}_p", :class=>'juli_toggle_node',  :style=>'display:none;') +
         #content_tag(:span, '[-] ', :id=>"#{id}_m", :class=>'juli_toggle_node') +
          @header_sequence.gen(n.level) + '. ' + n.str
        end
      end + "\n"
    end

    def visit_list(tag, n, options={})
      content_tag(tag, options) do
        n.array.inject('') do |result, child|
          result += content_tag(:li, list_item_css) do
            child.accept(self)
          end
        end
      end
    end

    # 1. parse str and build Juli::LineAbsyn tree
    # 1. visit the tree by HtmlLine and generate HTML
    def str2html(str)
      Juli::LineParser.new.parse(
          str,
          Juli::Wiki.wikinames).accept(@html_line_visitor)
    end

    def paragraph_css
      {:class=>'default'}
    end

    def blockquote_css
      {}
    end

    def list_item_css
      {}
    end

    # default dictionary list item term part CSS
    def dt_css
      {}
    end

    # default dictionary list item description part CSS
    def dd_css
      {}
    end

    # return specified template.
    #
    # 1. If 'template' macro is used, it is used rather than defined at
    #    conf file.
    # 1. Then, find_template() algorithm is used.
    #
    # Total template search logic is described in template(macro) document.
    def template
      find_template(@template || conf['template'], @opts[:t])
    end
  end

  # generate '1', '1.1', '1.2', ..., '2', '2.1', ...
  #
  # NOTE: When HeaderSequence was located before Html, rdoc generated
  # wrong document (as Juli::Visitor::HeaderSequence::Html rather than
  # Juli::Visitor::Html) so HeaderSequence is defined here.
  class HeaderSequence
    def initialize
      @header_number  = Array.new(6)
      @curr_level     = 0
    end

    def reset(level)
      for i in (level+1)...@header_number.size do
        @header_number[i] = 0
      end
    end

    def gen(level)
      reset(level) if level < @curr_level
      @header_number[level] = 0 if !@header_number[level]
      @header_number[level] += 1
      @curr_level = level
      h = []
      for i in 1..(level) do
        h << @header_number[i].to_s
      end
      h.join('.')
    end
  end
end
