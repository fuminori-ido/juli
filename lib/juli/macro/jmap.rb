# coding: UTF-8

module Juli
  module Macro
    # generate Map HTML.
    #
    # The purpose of this macro is to provide I/F for map.
    # When map-site(like google) service is discontinued, or
    # URL is changed, it is enough to change:
    #
    # 1. .juli/config jmap entry or
    # 1. this macro implementation.
    #
    # There is no need to modify all of wiki pages which use 'jmap' macro.
    #
    # 'J' of jmap stands for Juli. it is because 'map' in ruby is quite common
    # method so that necessary to avoid name confusion.
    #
    # Currently, Google map is used.
    class Jmap < Base
      # Thank you, http://mapki.com/wiki/Google_Map_Parameters !!
      DEFAULT_TEMPLATE = '<iframe width="425" height="350" frameborder="0" scrolling="no" marginheight="0" marginwidth="0" src="http://maps.google.com/maps?q=loc:%{coord}&amp;num=1&amp;ie=UTF8&amp;t=m&amp;z=14&amp;output=embed"></iframe><br /><small><a href="http://maps.google.com/maps?q=loc:%{coord}&amp;num=1&amp;ie=UTF8&amp;t=m&amp;z=14&amp;source=embed" style="color:#0000FF;text-align:left">View Larger Map</a></small>'

      def self.conf_template
        <<EOM
# HTML template to draw map.  If not set, default defined at
# Juli::Macro::Jmap::DEFAULT_TEMPLATE is used.
# %{coord} in the template wiil be replaced to the actual 1st parameter.
#
#jmap: '#{DEFAULT_TEMPLATE}'
EOM
      end

      def run(*args)
        template  = conf['jmap'] || DEFAULT_TEMPLATE
        coord     = args[0]
        template.gsub('%{coord}', coord)
      end
    end
  end
end
