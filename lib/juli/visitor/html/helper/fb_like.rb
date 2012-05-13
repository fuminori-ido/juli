module Juli::Visitor::Html::Helper
  # Helper-class for 'fb_like' helper
  class FbLike < AbstractHelper
    # default HTML template for facebook 'like' button.
    # You can customize it in .juli/config facebook.like.template entry.
    #
    # %s in the template will be replaced to the actual URL of
    # current wiki page.
    TEMPLATE =
      '<fb:like href="%s" ' +
          'send="false" layout="button_count" width="450" ' +
          'show_faces="false">' +
          '</fb:like>'

    def initialize
      @fb_conf  = conf['facebook']
    end

    # called on each parsed document
    def on_root(in_file, root)
      @in_file  = in_file
    end

    def run(*args)
      sprintf(template, conf['url_prefix'] + '/' + 
          to_wikiname(@in_file) + conf['ext'])
    end

  private
    def template
      @fb_conf && @fb_conf['like'] && @fb_conf['like']['template'] ||
      TEMPLATE
    end
  end
end
