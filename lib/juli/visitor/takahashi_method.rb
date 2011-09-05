module Juli::Visitor
  # This visits Intermediate tree and generates HTML for
  # 'Takahashi method' slideshow.
  #
  # Text files under juli-repository must have '.txt' extention.
  #
  # Almost all are the same as Html VISITOR.
  #
  # === OPTIONS
  # -t template::   specify template
  class TakahashiMethod < Html
    # bulk-mode in TakahashiMethod doesn't make sense so that
    # it just warns and return quickly.
    def run_bulk
      STDERR.printf("bulk-mode in TakahashiMethod is not supported.\n")
    end

  private
    # overwrite to generate simple <h# class=slide>...</h#>
    def header_link(n)
      content_tag("h#{n.level + 1}", :class=>'slide') do
        @header_sequence.gen(n.level) + '. ' + n.str
      end + "\n"
    end

    # specify paragraph css
    def paragraph_css
      {:class=>'default slide'}
    end

    # specify blockquote css
    def blockquote_css
      {:class=>'slide'}
    end

    # specify list item css
    def list_item_css
      {:class=>'slide'}
    end
  end
end
