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
      def on_root(file, root)
        @wikiname           = Juli::Util::to_wikiname(file)
        @page_db[@wikiname] = '1'
        @tag_exists         = false
      end

      def run(*args)
        for tag in args do
          @tag_exists   = true
          @tag_db[tag]  = '1'
          if @wikiname
            @tag_page_db[sprintf("%s%s%s", @wikiname, SEPARATOR, tag)] = '1'
          end
        end
        ''
      end

      # follow-up process to register 'no-tag' if there is no tag in the
      # file.
      def after_root(file, root)
        if !@tag_exists
          @tag_page_db[sprintf("%s%s%s", @wikiname, SEPARATOR, NO_TAG)] = '1'
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
            printf("  %s\n", key)
          end
          print "\n"
        end
      end
    end
  end
end
