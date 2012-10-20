# coding: UTF-8

require 'gdbm'

module Juli
  module Macro
    # Register tags of this document for tag-search.
    #
    # See 'doc/tag(macro).txt' for the detail how to use it.
    # Here is the implementation document.
    #
    # === Tag-DB ER-chart
    # tag <--->> tag_page <<---> page
    #
    # * tag DB value counts number of wikipages
    #
    # === FILES
    # JURI_REPO/.juli/tag.gdbm::      tag DB
    # JURI_REPO/.juli/page.gdbm::     page DB
    # JURI_REPO/.juli/tag_page.gdbm:: tag-page intersection DB
    class Tag < Base
      SEPARATOR = '_, _'
      NO_TAG    = '_no_tag_'

      attr_accessor :tag_db, :page_db, :tag_page_db

      def initialize
        super

        repo_dir      = File.join(juli_repo, Juli::REPO)
        @tag_db       = GDBM.open(File.join(repo_dir, 'tag.gdbm'))
        @page_db      = GDBM.open(File.join(repo_dir, 'page.gdbm'))
        @tag_page_db  = GDBM.open(File.join(repo_dir, 'tag_page.gdbm'))
      end

      # register page
      def on_root(file, root, visitor = nil)
        @wikiname           = Juli::Util::to_wikiname(file)
        @page_db[@wikiname] = '1'
        @tag_exists         = false
      end

      def run(*args)
        for tag in args do
          @tag_exists   = true

          # +1 on tag
          @tag_db[tag]  = ((@tag_db[tag] || '0').to_i + 1).to_s
          if @wikiname
            @tag_page_db[sprintf("%s%s%s", @wikiname, SEPARATOR, tag)] = '1'
          end
        end
        ''
      end

      # follow-up process to register 'no-tag' if there is no tag in the
      # file.
      def after_root(file, root)
        key = sprintf("%s%s%s", @wikiname, SEPARATOR, NO_TAG)
        if @tag_exists
          @tag_page_db.delete(key)
        else
          @tag_page_db[key] = '1'
        end
      end

      # value in gdbm in ruby 1.9 looks not to support encoding
      # (in other words, always set to ASCII-8BIT) so that
      # enforce to set it to UTF-8.
      def to_utf8(v)
        v.force_encoding(Encoding::UTF_8)
      end

      # return pages associated with key
      def pages(key)
        result = []
        for tag_page, val in @tag_page_db do
          if to_utf8(tag_page) =~ /^(.*)#{SEPARATOR}#{key}$/
            result << $1
          end
        end
        result
      end

      def max_tag_weight
        @tag_db.values.map{|v| v.to_i}.max || 1
      end

      # return 0..10 in tag weight v.s. max-weight
      def tag_weight_ratio(key)
        v = (@tag_db[key] || '0').to_i
        (v * 10 / max_tag_weight).to_i
      end

      # print DB info; debugging purpose.  How to use:
      #
      #   $ test/console
      #   > Dir.chdir('../test/repo')
      #   > include Juli::Util
      #   > t = Juli::Macro::Tag.new
      #   > t.dump
      def dump
        for db in %w(tag_db page_db tag_page_db) do
          printf("%s\n", db)
          for key, val in instance_variable_get('@' + db) do
            printf("  %s\t%s\n", key, val)
          end
          print "\n"
        end
      end
    end
  end
end
