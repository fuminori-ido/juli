module Juli::Visitor::Html::Helper
  # Helper-class for 'contents' helper
  class Contents < AbstractHelper
    class ContentsDrawer < Juli::Absyn::Visitor
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
      def visit_unordered_list(n); ''; end
      def visit_compact_dictionary_list(n); ''; end
      def visit_compact_dictionary_list_item(n); ''; end
      def visit_dictionary_list(n); ''; end
      def visit_dictionary_list_item(n); ''; end
  
      def visit_array(n)
        n.array.inject(''){|result, child|
          result += child.accept(self)
        }
      end

      def visit_chapter(n)
        content_tag(:li) do
          content_tag(:a, :href=>'#' + header_id(n)) do
            n.str
          end +
          content_tag(:ol) do
            n.blocks.accept(self)
          end
        end
      end
    end

    # called on each parsed document
    def on_root(in_file, root)
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
      contents_drawer = ContentsDrawer.new
      contents_drawer.content_tag(:ol) do
        @root.accept(contents_drawer)
      end
    end
  end
end
