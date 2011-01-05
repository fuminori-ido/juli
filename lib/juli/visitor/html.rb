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

  # define Juli specific HTML helper
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

  # Visitor::Html visits Intermediate tree and generates HTML
  class Html < ::Intermediate::Visitor
    include TagHelper
    include HtmlHelper
  
    def initialize
      super
      @header_number  = {}
     #@dom            = {}
    end
  
    def visit_default(n)
      content_tag(:p, :class=>'default') do
        n.str
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

    # visit root to generate:
    #
    # 1st:: HTML body
    # 2nd:: whole HTML by ERB.
    def run(in_file, root)
      IdAssigner.new.run(in_file, root)

      # store to instance var for 'contents' helper
      @root       = root
      title       = File.basename(in_file.gsub(/\.[^.]*$/, ''))
      javascript  = 'juli.js'
      stylesheet  = 'juli.css'
      body        = root.accept(self)
     #body       += gen_data            # add dom data
      erb         = ERB.new(File.read(File.join(PKG_ROOT, 'lib/template/wells.html')))
      out_file    = File.join(OUTPUT_TOP, File.basename(in_file).gsub(/\.[^\.]*/,'') + '.html')
      File.open(out_file, 'w') do |f|
        f.write(erb.result(binding))
      end
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

    def visit_list(tag, n)
      content_tag(tag) do
        n.array.inject('') do |result, child|
          result += child.accept(self)
        end
      end
    end

=begin
    # generate Javascript dom data
    def gen_data
      content_tag(:script) do
        "Juli.H1 = {'#{@dom[1].join(',')}'};\n"
      end
    end
=end
  end
end
