require 'juli/macro/template_base'

module Juli
  module Macro
    # Interwiki for Wikipedia
    class Wikipedia < TemplateBase
      DEFAULT_TEMPLATE = '<a href="http://en.wikipedia.org/wiki/%{wikipedia}">%{wikipedia}</a>'

      def self.conf_template
        <<EOM
# HTML template for wikipedia.
# '%{wikipedia}' in the template will be replaced by actual Wikipedia word:
#
#wikipedia: #{DEFAULT_TEMPLATE}
EOM
      end
    end
  end
end
