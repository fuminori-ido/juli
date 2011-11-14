module Juli
  module Command
    # used in both Juli::Command::Sitemap Juli::Command::RecentUpdate
    class FileEntry
      attr_accessor :path, :mtime
      def initialize(path, mtime)
        @path   = path
        @mtime  = mtime
      end
    end
  end
end
