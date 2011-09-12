module Juli::Visitor::Html::Helper
  # Helper-class for 'contents' helper
  class Contents < AbstractHelper
    class ContentsDrawer < Juli::Intermediate::Visitor
      include Juli::Visitor::Html::TagHelper
      include Juli::Visitor::Html::Helper

      def initialize
        super
        content_tag(:b, 'Contents') + ":\n"
      end 

      def visit_node(n); ''; end
      def visit_str(n); ''; end
      def visit_verbatim(n); ''; end
      def visit_ordered_list(n); ''; end
      def visit_ordered_list_item(n); ''; end
      def visit_unordered_list(n); ''; end
      def visit_unordered_list_item(n); ''; end
      def visit_dictionary_list(n); ''; end
      def visit_dictionary_list_item(n); ''; end
      def visit_long_dictionary_list(n); ''; end
      def visit_long_dictionary_list_item(n); ''; end
  
      def visit_array(n)
        n.array.inject(''){|result, child|
          result += child.accept(self)
        }
      end

      def visit_header(n)
        if n.level > 0
          content_tag(:li) do
            content_tag(:a, :href=>'#' + header_id(n)) do
              n.str
            end
          end
        else
          ''
        end +
        content_tag(:ol) do
          n.array.inject(''){|result, child|
            result += child.accept(self)
          }
        end
      end
    end

    # called on each parsed document
    def on_root(root)
      @root = root
    end

    # implementation of:
    #   contents
    #
    # which draws contents(a.k.a. outline) of this document.
    #
    # This visits document tree by ContentsDrawer visitor and
    # generate HTML contents list.
    def run(*args)
      @root.accept(ContentsDrawer.new)
    end
  end
end
