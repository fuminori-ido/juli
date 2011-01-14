require 'juli/util'

module Juli
  # When new file is added:
  #
  # 1. The filename becomes wikiname.
  # 1. scan all of files (includes itself because this also contains
  #    the wikiname), convert token to wiki-link if exists and
  #    generate HTML.
  # 
  # When a file is deleted:
  # 1. The filename (wikiname) is lost.
  # 1. scan all of files (includes itself because this also contains
  #    the wikiname), convert token to wiki-link if exists and
  #    generate HTML.
  #
  module Wiki
    include Juli::Util

    def build_wikinames
      wikiname = {}
      Dir.chdir(juli_repo){
        Dir.glob('**/*.txt'){|f|
          if f =~ /^(.*).txt$/
            wikiname[$1] = 1
          end
        }
      }
      wikiname.keys.sort_by{|a| -1 * a.length}
    end

    # global name to return wikinames data, which is just string array
    # ordered by length in descendant.
    def wikinames
      $_wikinames ||= build_wikinames
    end

    module_function :wikinames, :build_wikinames
  end  
end