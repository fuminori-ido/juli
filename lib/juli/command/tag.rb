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
             "<h2>#{I18n.t('tag_list')}</h2>\n".force_encoding('UTF-8')
      for tag in @tag_macro.tag_db.keys do
        body += gen_tag_list(tag)
      end
      body += gen_tag_list(
                  Juli::Macro::Tag::NO_TAG,
                  I18n.t(Juli::Macro::Tag::NO_TAG))
      body += "\n\n" + '<br/>'*100

      # tag detail
      for tag in @tag_macro.tag_db.keys do
        body += gen_tag_detail(tag)
      end
      body += gen_tag_detail(
                  Juli::Macro::Tag::NO_TAG,
                  I18n.t(Juli::Macro::Tag::NO_TAG))

      title       = I18n.t('tag_list')
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
    def gen_tag_list(tag, tag_label=tag)
      (content_tag(:a, tag_label,
          :class  => sprintf("juli_tag_%02d", @tag_macro.tag_weight_ratio(tag)),
          :href   => "##{tag}") + ' ').force_encoding('UTF-8')
    end

    def gen_tag_detail(tag, tag_label=tag)
      content_tag(:a, '', :name=>tag).force_encoding('UTF-8') +
      content_tag(:h2, tag_label).force_encoding('UTF-8') +
      '<table class="sitemap table table-hover">' +
      begin
        s = ''
        for page in @tag_macro.pages(@tag_macro.to_utf8(tag)) do
          file = page + '.txt'
          if !File.exist?(file)
            # Non-exist file may occur by manual delete/rename so that
            # delete the entry from tag-DB and don't produce tag entry 
            # from the tag-list page.
            @tag_macro.delete_page(file)
            next
          end

          page_utf8 = @tag_macro.to_utf8(page)
          s += sprintf("<tr><td><a href='%s'>%s</a></td><td>%s</td></tr>\n",
              page_utf8 + @tag_macro.to_utf8(conf['ext']),
              page_utf8,
              File.stat(file).mtime.strftime("%Y/%m/%d %H:%M"))
        end
        s
      end +
      '</table>' + 
      '<br/>' +
      '<a href="#top">' + I18n.t('back_to_top') + '</a>' +
      '<br/>'*30
    end
  end
end
