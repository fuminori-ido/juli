# coding: UTF-8

require 'gdbm'

module Juli
  module Macro
    # set ERB template.
    #
    # ERB template, which is used on generating HTML from juli-formatted text,
    # can be specified by:
    #
    # 1. juli(1) command line -t option.
    # 1. this macro
    # 1. .juli/config template directive.
    # 1. lib/juli/template
    #
    # See 'doc/template(macro).txt' for the detail how to use it.
    # Here is the implementation document.
    #
    # NOTE: Template class is <b>totally different</b> from TemplateBase.
    # Template is to specify ERB template, while TemplateBase is the
    # base class to provide HTML flagment replacement in a juli document.
    class Template < Base
      # save visitor for later use at run()
      def on_root(file, root, visitor = nil)
        @visitor = visitor
      end

      def run(*args)
        if @visitor.respond_to?('template=')
          @visitor.template = args[0]
        end
      end
    end
  end
end
