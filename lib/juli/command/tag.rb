# coding: UTF-8

module Juli::Command
  # generate _tag.shtml which shows tag-search-result HTML page.
  class Tag
    include Juli::Util
    include Juli::Visitor::Html::TagHelper
  
    def initialize
      @tag_macro = Juli::Macro::Tag.new
    end

    def run(opts)
      # tag list
      body = content_tag(:a, '', :name=>'top').force_encoding('UTF-8') +
             "<h2>tag list</h2>\n".force_encoding('UTF-8')
      for tag, val in @tag_macro.tag_db do
        body += (content_tag(:a, tag, :href=>"##{tag}") + ' ').force_encoding('UTF-8')
      end
      body += "\n\n" + '<br/>'*50

      # tag detail
      for tag, val in @tag_macro.tag_db do
        body += content_tag(:a, '', :name=>tag).force_encoding('UTF-8')
        body += content_tag(:h2, tag).force_encoding('UTF-8')
        body += '<table>'
        for page in @tag_macro.pages(@tag_macro.to_utf8(tag)) do
          page_utf8 = @tag_macro.to_utf8(page)
          body += sprintf("<tr><td><a href='%s'>%s</a></td><td>%s</td></tr>\n",
              page_utf8 + @tag_macro.to_utf8(conf['ext']),
              page_utf8,
              File.stat(page + '.txt').mtime.strftime("%Y/%m/%d %H:%M"))
        end
        body += '</table>' + 
                '<br/>' +
                '<a href="#top">Back to Top</a>' +
                '<br/>'*30
      end

      title       = 'tag list'
      contents    = ''
      prototype   = 'prototype.js'
      javascript  = 'juli.js'
      stylesheet  = 'juli.css'
      erb = ERB.new(File.read(find_template('simple.html')))
      File.open(File.join(conf['output_top'], '_tag.shtml'), 'w') do |f|
        f.write(erb.result(binding))
      end
    end

  private
  end
end
