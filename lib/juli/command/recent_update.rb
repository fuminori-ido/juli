module Juli::Command
  # generate recent_updates.shtml which lists recent updated entries.
  # The file is for server-side-include(SSI).
  class RecentUpdate
    include Juli::Util
    include Juli::Visitor::Html::TagHelper
  
    # define maximum file limit in order to reduce process time.
    FILE_LIMIT = 20

    # cache recent_update
    def initialize
      @file = []
      Dir.chdir(juli_repo){
        Dir.glob('**/*.txt'){|f|
          @file << FileEntry.new(f, File.stat(f).mtime)
        }
        @file.sort!{|a,b| b.mtime <=> a.mtime}
      }
    end

    def run(opts)
      File.open(File.join(conf['output_top'], 'recent_update.shtml'), 'w') do |f|
        f.write(gen(opts))
      end
    end

  private
    def gen(opts)
      title   = 'Recent Updates'
      content_tag(:table, :class=>'juli_recent_update') do
        content_tag(:tr, content_tag(:th, title, :colspan=>2)) +
        begin
          result = ''
          for i in 0..FILE_LIMIT-1 do
            f = @file[i]
            break if !f
            result +=
              content_tag(:tr) do
                content_tag(:td) do
                  content_tag(:a, f.path.gsub(/.txt$/, ''),
                    :href=>f.path.gsub(/.txt$/, conf['ext'])) + "\n<br/>"
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
