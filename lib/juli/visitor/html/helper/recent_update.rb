module Juli::Visitor::Html::Helper
  # Helper-class for 'recent_update' helper
  class RecentUpdate < AbstractHelper
    include Juli::Util
    include Juli::Visitor::Html::TagHelper

    class FileEntry
      attr_accessor :path, :mtime
      def initialize(path, mtime)
        @path   = path
        @mtime  = mtime
      end
    end

    # Even each recent_update() calling can specify number of entries,
    # define maximum file limit in order to reduce process time.
    FILE_LIMIT = 30
  
    # cache recent_update
    def initialize
      super

      @file = []
      Dir.chdir(juli_repo){
        Dir.glob('**/*.txt'){|f|
          break if @file.size >= FILE_LIMIT
          @file << FileEntry.new(f, File.stat(f).mtime)
        }
        @file.sort!{|a,b| b.mtime <=> a.mtime}
      }
    end

    # implementation of:
    #   recent_update(number = FILE_LIMIT, title='Recent Updates')
    def run(*args)
      super
      number = if args[0].class == Fixnum
                  args[0]
                  args.shift
               else
                  FILE_LIMIT
               end
      title = if args[0].class == String
                args[0]
              else
                'Recent Updates'
              end
      content_tag(:table, :class=>'juli_recent_update') do
        content_tag(:tr, content_tag(:th, title, :colspan=>2)) +
        begin
          result = ''
          for i in 0..number-1 do
            f = @file[i]
            break if !f
            result +=
              content_tag(:tr) do
                content_tag(:td) do
                  content_tag(:a, f.path.gsub(/.txt$/, ''),
                    :href=>f.path.gsub(/.txt$/, '.html')) + "\n<br/>"
                end +
                content_tag(:td, f.mtime.strftime('%Y/%m/%d'))
              end
          end
          result
        end
      end
    end
  end
end
