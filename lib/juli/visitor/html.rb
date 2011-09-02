require 'fileutils'
require 'pathname'
require 'juli/util'
require 'juli/line_parser.tab'
require 'juli/intermediate'

module Juli::Visitor
  # This visits Intermediate tree and generates HTML
  #
  # Text files under juli-repository must have '.txt' extention.
  #
  # === OPTIONS
  # -f::            force update
  # -t template::   specify template
  class Html < Juli::Intermediate::Visitor
    require 'juli/visitor/html/tag_helper'
    require 'juli/visitor/html/helper'
    
    include Juli::Util
    include Juli::Visitor::Html::TagHelper
    include Juli::Visitor::Html::Helper

    # assign DOM id on header node.
    #
    # IdAssigner should be executed before running Html visitor since
    # ContentsDrawer also refers DOM id.  That is the reason why DOM id
    # assignment is isolated from Html visitor.
    class IdAssigner < Juli::Intermediate::Visitor
      def initialize(opts={})
        super
        @uniq_id_seed   = 0
      end
    
      def visit_header(n)
        if n.level > 0
          n.dom_id = uniq_id(n.level)
        end
        for child in n.array do
          child.accept(self)
        end
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
    class HtmlLine < Juli::LineAbsyn::Visitor
      include TagHelper
  
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

      for helper in @_helpers do
        helper.on_root(root)
      end

      # store to instance var for 'contents' helper
      @root       = root
      title       = File.basename(in_file.gsub(/\.[^.]*$/, ''))
      prototype   = relative_from(in_file, 'prototype.js')
      javascript  = relative_from(in_file, 'juli.js')
      stylesheet  = relative_from(in_file, 'juli.css')
      sitemap     = relative_from(in_file, 'sitemap' + conf['ext'])
      body        = root.accept(self)
      erb         = ERB.new(File.read(find_template))
      out_path    = out_filename(in_file)
      mkdir(out_path)
      File.open(out_path, 'w') do |f|
        f.write(erb.result(binding))
      end
      printf("generated:       %s\n", out_filename(in_file))
    end
  
    def visit_str(n)
      case n.parent
      when Juli::Intermediate::ListItem
        if n.level > n.parent.level
          # quote; trim last white spaces at generating phase
          content_tag(:blockquote, content_tag(:pre, n.str.gsub(/\s+\z/m, '')))
        else
          # just string (no quote, no paragraph)
          str2html(n.str)
        end
      else
        if n.level > 0
          # quote; trim last white spaces at generating phase
          content_tag(:blockquote, content_tag(:pre, n.str.gsub(/\s+\z/m, '')))
        else
          # paragraph
          content_tag(:p, :class=>'default') do
            str2html(n.str)
          end
        end
      end
    end
  
    def visit_header(n)
      if n.level == 0
        header_content(n)
      else
        header_link(n) +
        content_tag(:div, :id=>n.dom_id) do
          header_content(n)
        end + "\n"
      end
    end

    def visit_ordered_list(n)
      visit_list(:ol, n)
    end

    def visit_ordered_list_item(n)
      content_tag(:li) do
        n.array.inject('') do |result, str_or_quote|
          result += str_or_quote.accept(self)
        end
      end
    end

    def visit_unordered_list(n)
      visit_list(:ul, n)
    end

    def visit_unordered_list_item(n)
      content_tag(:li) do
        n.array.inject('') do |result, str_or_quote|
          result += str_or_quote.accept(self)
        end
      end
    end

    def visit_dictionary_list(n)
      visit_list(:table, n, :class=>'juli_dictionary')
    end

    def visit_dictionary_list_item(n)
      content_tag(:tr) do
        content_tag(:td, str2html(n.term) + ':', :nowrap=>true) +
        content_tag(:td, str2html(n.str))
      end
    end

    # find erb template in the following order:
    #
    # if -t options is specified:
    #   1st) template_path in absolute or relative from current dir, or
    #   2nd) -t template_path in JULI_REPO/.juli/, or
    #   3rd) -t template_path in lib/juli/template/
    #   otherwise, error
    # else:
    #   4th) {template} in JULI_REPO/.juli/, or
    #   5th) {template} in lib/juli/template.
    #   otherwise, error
    #
    # Where, {template} means conf['template']
    def find_template
      dirs = [File.join(juli_repo, Juli::REPO), Juli::TEMPLATE_PATH]
      if @opts[:t]
        if File.exist?(@opts[:t])
          @opts[:t]
        else
          find_template_sub(@opts[:t])
        end
      else
        find_template_sub(conf['template'])
      end
    end

  private
    HELPER = [
      Juli::Visitor::Html::Helper::Contents
    ]

    # Similar to Rails underscore() method.
    #
    # Example: 'A::B::HelperMethod' -> 'helper_method'
    def self.to_method(helper_class)
      helper_class.to_s.gsub(/.*::/,'').
          gsub(/([A-Z]+)([A-Z][a-z])/,'\1_\2').
          gsub(/([a-z\d])([A-Z])/,'\1_\2').
          tr("-", "_").
          downcase
    end

    def copy_to_output_top(file)
      src   = File.join(Juli::TEMPLATE_PATH, file)
      dest  = File.join(conf['output_top'], file)
      return if File.exist?(dest) && File.stat(dest).mtime >= File.stat(src).mtime

      FileUtils.cp(src, dest, :preserve=>true)
    end

    # define each XHelper instance variable as '@_helper_x_helper'.
    # These objects will be used at helper method 'x_helper()',
    # which is also defined below (*).
    def register_helper
      @_helpers = []
      for helper_class in HELPER do
        eval <<-end_of_dynamic_define_of_instance_var
          @_helper_#{Html.to_method(helper_class)} = #{helper_class}.new
          @_helpers << @_helper_#{Html.to_method(helper_class)}
        end_of_dynamic_define_of_instance_var
      end
    end

    # (*) define helper method 'x_helper()' from XHelper class to call
    # @_helper_Helper1.run(*args)
    for helper_class in HELPER do
      class_eval <<-end_of_dynamic_method, __FILE__, __LINE__ + 1
        def #{to_method(helper_class)}(*args)
          @_helper_#{to_method(helper_class)}.run(*args)
        end
      end_of_dynamic_method
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
        out_file = out_filename(f)
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

    # common for all h0, h1, ..., h6
    def header_content(n)
      n.array.inject(''){|result, child|
        result += child.accept(self)
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
          content_tag(:span, '[+] ', :id=>"#{id}_p", :class=>'juli_toggle_node',  :style=>'display:none;') +
          content_tag(:span, '[-] ', :id=>"#{id}_m", :class=>'juli_toggle_node') +
          @header_sequence.gen(n.level) + '. ' + n.str
        end
      end + "\n"
    end

    def visit_list(tag, n, options={})
      content_tag(tag, options) do
        n.array.inject('') do |result, child|
          result += child.accept(self)
        end
      end
    end

    # 1. parse str and build Juli::LineAbsyn tree
    # 1. visit the tree by HtmlLine and generate HTML
    def str2html(str)
      Juli::LineParser.new.parse(str, Juli::Wiki.wikinames).accept(HtmlLine.new)
    end

    # find template 't' in dirs
    def find_template_sub(t)
      for path in [File.join(juli_repo, Juli::REPO), Juli::TEMPLATE_PATH] do
        template = File.join(path, t)
        return template if File.exist?(template)
      end
      raise Errno::ENOENT, "no #{t} found"
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
