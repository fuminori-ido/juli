module Juli::Visitor::Html::Helper
  # Helper-class for 'fb_like' helper
  class FbComments < AbstractHelper
    # default HTML template for facebook 'like' button.
    # You can customize it in .juli/config facebook.like.template entry.
    #
    # %{href} in the template will be replaced to the actual URL of
    # current wiki page.
    TEMPLATE =
      '<fb:comments href="%{href}" num_posts="2" width="470">' +
      '</fb:comments>'

    def initialize
      @fb_conf  = conf['facebook']
    end

    # called on each parsed document
    def on_root(in_file, root)
      @in_file  = in_file
    end

    def run(*args)
      template.gsub('%{href}',
          conf['url_prefix'] + '/' + to_wikiname(@in_file) + conf['ext'])
    end

  private
    def template
      @fb_conf && @fb_conf['comments'] && @fb_conf['comments']['template'] ||
      TEMPLATE
    end
  end
end
