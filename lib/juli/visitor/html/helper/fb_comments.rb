module Juli::Visitor::Html::Helper
  # Helper-class for 'fb_like' helper
  class FbComments < AbstractHelper
    # default HTML template for facebook 'like' button.
    # You can customize it in .juli/config facebook.like.template entry.
    #
    # %{href} in the template will be replaced to the actual URL of
    # current wiki page.
    DEFAULT_TEMPLATE =
      '<fb:comments href="%{href}" num_posts="2" width="470">' +
      '</fb:comments>'

    # called on 'juli init' to generate config sample template.
    def self.conf_template
      <<EOM
#
#url_prefix: 'http://YOUR_HOST/juli'
#facebook:
#  like:
#    template:  '#{Juli::Visitor::Html::Helper::FbLike::DEFAULT_TEMPLATE}'
#  comments:
#    template:  '#{DEFAULT_TEMPLATE}'
EOM
    end

    def initialize
      @fb_conf  = conf['facebook']
    end

    # set default value in conf if no .juli/conf defined.
    #
    # Please overwrite this method when this implementation is not your
    # case.
    def set_conf_default(conf)
      conf['facebook'] = {} if !conf['facebook']
      if !conf['facebook']['comments']
        conf['facebook']['comments'] = {
          'template'  => self.class::DEFAULT_TEMPLATE
        }
      end
      if !conf['facebook']['like']
        conf['facebook']['like'] = {
          'template'  => Juli::Visitor::Html::Helper::FbLike::DEFAULT_TEMPLATE
        }
      end
    end

    # called on each parsed document
    def on_root(in_file, root)
      @in_file  = in_file
    end

    def run(*args)
      raise Juli::NoConfig if !conf['url_prefix']
      raise Juli::NoConfig if !@in_file

      template.gsub('%{href}',
          conf['url_prefix'] + '/' + to_wikiname(@in_file) + conf['ext'])
    end

  private
    def template
      @fb_conf['comments']['template']
    end
  end
end
