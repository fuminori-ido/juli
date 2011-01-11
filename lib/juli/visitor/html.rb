require 'pathname'
require 'juli/util'
require 'juli/line_parser.tab'
require 'juli/intermediate'

module Visitor
  # copied from Rails
  module TagHelper
    def tag(name, options = nil, open = false)
      "<#{name}#{tag_options(options) if options}#{open ? ">" : " />"}"
    end
  
    def content_tag(name, content_or_options_with_block = nil, options = nil, &block)
      if block_given?
        options = content_or_options_with_block if content_or_options_with_block.is_a?(Hash)
        content_tag_string(name, block.call, options)
      else
        content_tag_string(name, content_or_options_with_block, options)
      end
    end
  
  private
    BOOLEAN_ATTRIBUTES = %w(disabled readonly multiple checked)
    BOOLEAN_ATTRIBUTES << BOOLEAN_ATTRIBUTES.map(&:to_sym)
  
    def content_tag_string(name, content, options)
      tag_options = tag_options(options) if options
      "<#{name}#{tag_options}>#{content}</#{name}>"
    end
  
    def tag_options(options)
      if options != {}
        attrs = []
        options.each_pair do |key, value|
          if BOOLEAN_ATTRIBUTES.include?(key)
            attrs << key if value
          else
            attrs << %(#{key}="#{value}") if !value.nil?
          end
        end
        " #{attrs.sort * ' '}" unless attrs.empty?
      end
    end
  end

  # define Juli specific HTML helper.
  #
  # Any method here can be used at html template.
  module HtmlHelper
    # TRICKY PART: header_id is used for 'contents' helper link.
    # Intermediate::HeaderNode.dom_id cannot be used directory for
    # this purpose since when clicking a header of 'contents',
    # document jumps to its contents rather than header so that
    # header is hidden on browser.  To resolve this, header_id
    # is required for 'contents' helper and it is set at Html visitor.
    def header_id(n)
      "#{n.dom_id}_header"
    end


    # draw contents(outline) of this document.
    def contents
      ContentsDrawer.new.run(nil, @root)
    end

    # dest's relative path from src
    #
    # === EXAMPLE
    # relative_from('a.txt',   'juli.js'):: → './juli.js'
    # relative_from('a/b.txt', 'juli.js'):: → '../juli.js'
    def relative_from(src, dest)
      result = []
      Pathname.new(File.dirname(src)).descend{|dir|
        result << (dir.to_s == '.' ? '.' : '..')
      }
      File.join(result, dest)
    end
  end

  # generate contents
  class ContentsDrawer < ::Intermediate::Visitor
    include TagHelper
    include HtmlHelper

    def visit_node(n); ''; end
    def visit_default(n); ''; end
    def visit_ordered_list(n); ''; end
    def visit_ordered_list_item(n); ''; end
    def visit_unordered_list(n); ''; end
    def visit_unordered_list_item(n); ''; end
    def visit_dictionary_list(n); ''; end
    def visit_dictionary_list_item(n); ''; end
    def visit_quote(n); ''; end

    def visit_header(n)
      if n.level > 0
        content_tag(:li) do
          content_tag(:a, :href=>'#' + header_id(n)) do
            n.str
          end
        end
      else
        ''
      end +
      content_tag(:ol) do
        n.array.inject(''){|result, child|
          result += child.accept(self)
        }
      end
    end

    def run(in_file, root)
      root.accept(self)
    end
  end

  # assign DOM id on header node.
  #
  # IdAssigner should be executed before running Html visitor since
  # ContentsDrawer also refers DOM id.  That is the reason why DOM id
  # assignment is isolated from Html visitor.
  class IdAssigner < ::Intermediate::Visitor
    def initialize
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

  module Util
    # mkdir for out_file if necessary
    def mkdir(path)
      dir = File.dirname(path)
      if !File.directory?(dir)
        FileUtils.mkdir_p(dir)
      end
    end

    # === INPUTS
    # in_filename:: relative path under repository
    #
    # === RETURN
    # full path of out filename
    #
    # === EXAMPLE
    # diary/2010/12/31.txt -> OUTPUT_TOP/diary/2010/12/31.html
    #
    def out_filename(in_filename)
      File.join(conf['output_top'], in_filename.gsub(/\.[^\.]*/,'') + '.html')
    end

    # === INPUTS
    # out_filename:: relative path under OUTPUT_TOP
    #
    # === RETURN
    # relative path of in-filename, but **no extention**.
    #
    # === EXAMPLE
    # diary/2010/12/31.html -> diary/2010/12/31
    def in_filename(out_filename)
      File.join(File.dirname(out_filename), File.basename(out_filename).gsub(/\.[^\.]*/,''))
    end
  end

  class HtmlLine < ::LineAbsyn::Visitor
    include TagHelper
    include HtmlHelper

    def visit_array(n)
      n.array.inject('') do |result, n|
        result += n.accept(self)
      end
    end

    def visit_string(n)
      n.str
    end

    def visit_wikiname(n)
      content_tag(:a, n.str, :class=>'wiki', :href=>n.str + '.html')
    end
  end

  # Visitor::Html visits Intermediate tree and generates HTML
  #
  # Text files under juli-repository must have '.txt' extention.
  class Html < ::Intermediate::Visitor
    include TagHelper
    include HtmlHelper
    include Util
    extend  Util

    def self.copy_to_output_top(file)
      dest_path = File.join(conf['output_top'], file)
      if !File.exist?(dest_path)
        FileUtils.cp(File.join(Juli::TEMPLATE_PATH, file), dest_path,
            :preserve=>true)
      end
    end
    
    # Html sepecific initialization does:
    #
    # 1. create output_top.
    # 1. copy *.js, *.css files to output_top/
    #
    # NOTE: this is executed every juli(1) run with -g html option
    # (usually 99% is so), so be careful to avoid multiple initialization.
    def self.init
      if !File.directory?(conf['output_top'])
        FileUtils.mkdir_p(conf['output_top'])
      end
      copy_to_output_top('prototype.js')
      copy_to_output_top('juli.js')
      copy_to_output_top('juli.css')
    end

    # run in bulk-mode.  In Html visitor, it sync juli-repository and
    # OUTPUT_TOP.
    def self.run
      sync
    end

    # synchronize repository and OUTPUT_TOP:
    #
    # 1. new file exists, generate it.
    # 1. repo's file timestamp is newer than the one under OUTPUT_TOP, regenerate it.
    # 1. correspondent file of OUTPUT_TOP/.../f doesn't exist in repo, delete it.
    def self.sync
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
        if File.exist?(out_file) &&
           File.stat(out_file).mtime >= File.stat(File.join(juli_repo,f)).mtime
          #printf("already updated: %s\n", out_file)
        else
          Juli::Parser.new.parse(f, self)
        end
      end

      # When correspondent file of OUTPUT_TOP/.../f doesn't exist in repo,
      # delete it.
      Dir.chdir(conf['output_top']){
        Dir.glob('**/*.html'){|f|
          in_file = File.join(juli_repo, in_filename(f))
          if !File.exist?(in_file) && !File.exist?(in_file + '.txt')
            FileUtils.rm(f)
            printf("%s is deleted since no correspondent source text.\n", f)
          end
        }
      }
    end

    def initialize
      super
      @header_number  = {}
    end
  
    def visit_default(n)
      content_tag(:p, :class=>'default') do
        n.line.accept(HtmlLine.new)
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
      content_tag(:li, n.str)
    end

    def visit_unordered_list(n)
      visit_list(:ul, n)
    end

    def visit_unordered_list_item(n)
      content_tag(:li, n.str)
    end

    def visit_dictionary_list(n)
      visit_list(:table, n, :class=>'juli_dictionary')
    end

    def visit_dictionary_list_item(n)
      content_tag(:tr) do
        content_tag(:td, n.term + ':') + content_tag(:td, n.str)
      end
    end

    def visit_quote(n)
      content_tag(:blockquote, content_tag(:pre, n.str))
    end

    # visit root to generate:
    #
    # 1st:: HTML body
    # 2nd:: whole HTML by ERB.
    def run(in_file, root)
      IdAssigner.new.run(in_file, root)

      # store to instance var for 'contents' helper
      @root       = root
      title       = File.basename(in_file.gsub(/\.[^.]*$/, ''))
      prototype   = relative_from(in_file, 'prototype.js')
      javascript  = relative_from(in_file, 'juli.js')
      stylesheet  = relative_from(in_file, 'juli.css')
      body        = root.accept(self)
      erb         = ERB.new(File.read(File.join(Juli::PKG_ROOT, 'lib/template/wells.html')))
      out_path    = out_filename(in_file)
      mkdir(out_path)
      File.open(out_path, 'w') do |f|
        f.write(erb.result(binding))
      end
      printf("generated:       %s\n", out_filename(in_file))
    end

  private

    # common for all h0, h1, ..., h6
    def header_content(n)
      n.array.inject(''){|result, child|
        result += child.accept(self)
      }
    end

    # draw <hi>... link, where i=1..6
    def header_link(n)
      id = n.dom_id
      content_tag("h#{n.level}", :id=>header_id(n)) do
        content_tag(:span, :class=>'juli_toggle', :onclick=>"Juli.toggle('#{id}');") do
          content_tag(:span, '[+] ', :id=>"#{id}_p", :class=>'juli_toggle_node',  :style=>'display:none;') +
          content_tag(:span, '[-] ', :id=>"#{id}_m", :class=>'juli_toggle_node') +
          header_seq(n) + '. ' + n.str
        end
      end + "\n"
    end

    def header_seq(n)
      if !@header_number[n.level]
        @header_number[n.level] = 0
      end
      @header_number[n.level] += 1
      h = []
      for i in 1..(n.level) do
        h << @header_number[i].to_s
      end
      h.join('.')
    end

    def visit_list(tag, n, options={})
      content_tag(tag, options) do
        n.array.inject('') do |result, child|
          result += child.accept(self)
        end
      end
    end
  end
end
