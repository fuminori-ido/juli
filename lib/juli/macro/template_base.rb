module Juli
  module Macro
    # Base class for HTML template related macros.
    #
    # Derived class can provide HTML template replacement with minimum
    # implementation.  Please see Wikipedia case as an example.
    class TemplateBase < Base
      DEFAULT_TEMPLATE = ''

      def self.conf_template
        ''
      end

      # return key string used for conf-key
      #
      # Please overwrite this method if it is not just underscore-ed.
      def conf_key
        Juli::Util::underscore(self.class.to_s)
      end

      # set default value in conf if no .juli/conf defined.
      #
      # Please overwrite this method when this implementation is not your
      # case.
      def set_conf_default(conf)
        if !conf[conf_key]
          conf[conf_key] = self.class::DEFAULT_TEMPLATE
        end
      end

      # return string used to be replaced with %{...} in conf[conf_key] string.
      #
      # Please overwrite this method if it is not just underscore-ed.
      def place_holder
        conf_key
      end

      def run(*args)
        template = conf[conf_key]
        template.gsub("%{#{place_holder}}", args[0])
      end
    end
  end
end
