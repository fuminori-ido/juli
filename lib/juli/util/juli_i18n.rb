require 'i18n'

module Juli
  module Util
    # Locale is determined by 'locale' entry in .juli/config (default = en).
    #
    # Translation file is used at the following priority:
    #
    # 1. .juli/LC.yml
    # 1. LIB/juli/template/locale/LC.yml
    #
    # Where, LC is the value of 'locale' config (default = en), and
    # LIB is ruby library directory (e.g. /usr/lib/lib/ruby/site_ruby/1.9.1/).
    class JuliI18n
      def initialize(conf, juli_repo)
        I18n.locale = conf['locale'] || :en

        for candidate_dir in [
            File.join(juli_repo, Juli::REPO),
            File.join(Juli::TEMPLATE_PATH, 'locale')
            ] do
          locale_yml = File.join(candidate_dir, "#{I18n.locale}.yml")
          if File.exist?(locale_yml)
            I18n.load_path = [locale_yml]
            return
          end
        end
        raise Errno::ENOENT, "no #{I18n.locale}.yml found"
      end
    end
  end
end
