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
    def toggle_top(label = 'Toggle Top')
      content_tag(:a, label, :onclick=>"Juli.toggle_top()")
    end
  end

  # Visitor::Html visits Intermediate tree and generates HTML
  class Html < ::Intermediate::Visitor
    include TagHelper
  
    def initialize
      super
      @uniq_id_seed   = 0
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
        id = uniq_id(n.level)
        header_link(n, id) +
        content_tag(:div, :id=>id) do
          header_content(n)
        end + "\n"
      end
    end

    # visit root to generate:
    #
    # 1st:: HTML body
    # 2nd:: whole HTML by ERB.
    def run(in_file, root)
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
    # generate uniq_id, and track it for each level to be used later
    def uniq_id(level)
      @uniq_id_seed += 1
      result = sprintf("j%05d", @uniq_id_seed)
=begin
      if !@dom[level]
        @dom[level] = []
      end
      @dom[level] << result
=end
      result
    end

    # common for all h0, h1, ..., h6
    def header_content(n)
      n.array.inject(''){|result, child|
        result += child.accept(self)
      }
    end

    # draw <hi>... link, where i=1..6
    def header_link(n, id)
      content_tag("h#{n.level}") do
        content_tag(:span, :class=>'juli_toggle', :onclick=>"Juli.toggle('#{id}');") do
          content_tag(:span, '[+] ', :id=>"#{id}_p", :class=>'juli_toggle_node',  :style=>'display:none;') +
          content_tag(:span, '[-] ', :id=>"#{id}_m", :class=>'juli_toggle_node') +
          header_seq(n) + '. ' + n.name
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
