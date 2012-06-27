module Juli::Visitor::Html::Helper
  # Helper-class for 'contents' helper
  class Contents < AbstractHelper
    # Check if chapter exists or not
    class ChapterChecker < Juli::Absyn::Visitor
      attr_accessor :chapter_exists

      def initialize(opts = {})
        @chapter_exists = false
        super
      end

      def visit_chapter(n)
        @chapter_exists = true
      end
    end

    class ContentsDrawer < Juli::Absyn::Visitor
      include Juli::Visitor::Html::TagHelper
      include Juli::Visitor::Html::Helper

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
      chapter_checker = ChapterChecker.new
      @root.accept(chapter_checker)
      if chapter_checker.chapter_exists
        contents_drawer.content_tag(:b, I18n.t('contents')) +
        contents_drawer.content_tag(:ol) do
          @root.accept(contents_drawer)
        end
      else
        ''
      end
    end
  end
end
