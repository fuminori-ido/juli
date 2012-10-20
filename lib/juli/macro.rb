module Juli
  module Macro
    class Base
      include Juli::Util

      # called on 'juli init' to generate config sample template.
      def self.conf_template
        ''
      end

      # called when juli(1) starts.
      def initialize
      end

      # called on setting up conf to set default key=val
      def set_conf_default(conf)
      end

      # called on each parsed document
      def on_root(file, root, visitor = nil)
      end

      # called on each macro as "\{macro_name args...}" in text.
      # String should be returned.
      def run(*args)
        ''
      end

      # called at final on each parsed document
      def after_root(file, root)
      end

    end

    Dir.glob(File.join(File.dirname(__FILE__), 'macro/*.rb')){|m|
      require File.join('juli/macro', File.basename(m))
    }
  end
end
