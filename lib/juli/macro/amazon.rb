module Juli
  module Macro
    # generate Amazon link
    #
    # Amazon link template can be defined at 'amazon' entry in
    # JULI_REPO/.juli/config.
    #
    # if it is not defined, then default template here is used.
    class Amazon < Base
      DEFAULT_TEMPLATE = <<-EOS
        <iframe src="http://rcm-jp.amazon.co.jp/e/cm?t=wells00-22&o=9&p=8&l=as1&asins=%{asins}&ref=tf_til&fc1=000000&IS2=1&lt1=_blank&m=amazon&lc1=0000FF&bc1=000000&bg1=FFFFFF&f=ifr"
          style="float:right; width:120px;height:240px;"
          scrolling="no" marginwidth="0" marginheight="0" frameborder="0"
          ></iframe>
      EOS

      def self.conf_template
        <<EOM
# Amazon association link with any ASIN can be rendered
# at any location in juli text.  Its template is as follows.
# This HTML is just an example so that you can change as you like.
# '%{asins}' in the template will be replaced by actual ASIN:
#
#amazon:     '<iframe src="http://rcm-jp.amazon.co.jp/e/cm?o=9&p=8&l=as1&asins=%{asins}&ref=tf_til&fc1=000000&IS2=1&lt1=_blank&m=amazon&lc1=0000FF&bc1=000000&bg1=FFFFFF&f=ifr" style="float:right; width:120px;height:240px;" scrolling="no" marginwidth="0" marginheight="0" frameborder="0"></iframe>'
EOM
      end

      def run(*args)
        template = conf['amazon'] || DEFAULT_TEMPLATE
        template.gsub('%{asins}', args[0])
      end
    end
  end
end
