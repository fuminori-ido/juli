module Juli::Visitor
  # This visits Absyn tree and generates HTML for Slideshow.
  #
  # Text files under juli-repository must have '.txt' extention.
  #
  # Almost all are the same as Html VISITOR.
  #
  # === OPTIONS
  # -t template::   specify template
  class Slidy < Html
    # bulk-mode for slideshow generation doesn't make sense so that
    # it just warns and return quickly.
    def run_bulk
      STDERR.printf("bulk-mode in Slidy is not supported.\n")
    end

    # overwrite to:
    # * add 'slide' stylesheet-class at level==1
    # * include all contents in 'slide' stylesheet-class even title
    def visit_chapter(n)
      attr = {:id=>n.dom_id}
      if n.level==1
        attr.merge!(:class=>'slide')
      end
      content_tag(:div, attr) do
        header_link(n) +
        n.blocks.accept(self)
      end + "\n"
    end

  private
    # overwrite to generate simple <h#>...</h#>
    def header_link(n)
      content_tag("h#{n.level + 1}") do
        @header_sequence.gen(n.level) + '. ' + n.str
      end + "\n"
    end
  end
end
