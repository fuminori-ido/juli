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
    # encode(=escape) '(', ')'
    #
    # === EXAMPLE
    # 'juli(1)' -> 'juli\(1\)'
    def encode(str)
      str.gsub(/\(/, '\(').gsub(/\)/, '\)')
    end

    # decode '(', ')'
    #
    # === EXAMPLE
    # 'juli\(1\)' -> 'juli(1)'
    def decode(str)
      str.gsub(/\\\(/, '(').gsub(/\\\)/, ')')
    end

    def build_wikinames
      wikiname = {}
      Dir.chdir(Juli::Util.juli_repo){
        Dir.glob('**/*.txt'){|f|
          wikiname[encode(Juli::Util.to_wikiname(f))] = 1
        }
      }
      wikiname.keys.sort_by{|a| -1 * a.length}
    end

    # global name to return wikinames data, which is just string array
    # ordered by length in descendant.
    def wikinames
      $_wikinames ||= build_wikinames
    end

    module_function :wikinames, :build_wikinames, :encode, :decode
  end  
end