module Juli::Command
  # generate sitemap.html and sitemap_order_by_mtime_DESC.html
  # under $JULI_REPO
  class Sitemap
    include Juli::Util
    include Juli::Visitor::Html::TagHelper

    # cache File info
    def initialize
      @file = []
      Dir.chdir(juli_repo){
        Dir.glob('**/*.txt'){|f|
          @file << FileEntry.new(f, File.stat(f).mtime)
        }
      }
    end

    def run(opts)
      sitemap_sub('sitemap.html'){|files| files.sort}
      sitemap_sub('sitemap_order_by_mtime_DESC.html'){|files|
        files.sort{|a,b| File.stat(a).mtime <=> File.stat(b).mtime}.reverse
      }
    end

  private
    # === INPUTS
    # name::  basename without extention for sitemap
    # block:: sort condition
    def sitemap_sub(name, &block)
      Dir.chdir(juli_repo) {
        outdir = File.join(conf['output_top'])
        FileUtils.mkdir(outdir) if !File.directory?(outdir)
        body  = ''
        count = 0
        for textfile in yield(Dir.glob('**/*.txt')) do
          count += 1
          body += sprintf("<tr><td class='num'>%d</td><td><a href='%s'>%s</a></td><td>%s</td></tr>\n",
                      count,
                      textfile.gsub(/.txt$/, conf['ext']),  # url
                      textfile.gsub(/.txt$/, ''),           # label
                      File.stat(textfile).mtime.strftime("%Y/%m/%d %H:%M:%S"))
        end

        title       = 'Sitemap'
        prototype   = 'prototype.js'
        javascript  = 'juli.js'
        stylesheet  = 'juli.css'
        erb         = ERB.new(File.read(find_template(name)))
        File.open(out_filename(name), 'w') do |f|
          f.write(erb.result(binding))
        end
      }
    end
  end
end
