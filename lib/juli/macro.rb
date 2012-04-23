module Juli
  module Macro
    class Base
      # called on 'juli init' to generate config sample template.
      def self.conf_template
        ''
      end

      # called when juli(1) starts.
      def initialize
      end

      # called on each parsed document
     #def on_root(root)
     #end

      # called on each macro as "\{macro_name args...}" in text
      def run(*args)
      end
    end

    Dir.glob(File.join(File.dirname(__FILE__), 'macro/*.rb')){|m|
      require File.join('juli/macro', File.basename(m))
    }
  end
end
