module Grit
  class Commit

    # Fix: NoMethodError: undefined method 'touch' for Grit::Commit
    # see: model Comment belongs_to :commentable
    def touch
      true
    end
  end

  class Submodule
    def binary?
      false
    end
  end

  class Blob
    include Linguist::BlobHelper

    MAX_VIEW_SIZE = 2.megabytes
    MAX_DATA_SIZE = 50.megabytes

    def data_with_limit
      !huge? ? data_without_limit : nil # 'Error: blob is too big'
    end
    alias_method_chain :data, :limit

    def large?
      size.to_i > MAX_VIEW_SIZE
    end

    def huge?
      size.to_i > MAX_DATA_SIZE
    end

    def render_as
      @render_as ||= case
      when large?; :binary
      when image?; :image
      when text?; :text
      else
        :binary
      end
    end

    attr_accessor :raw_mime_type
    def raw_mime_type
      return @raw_mime_type if @raw_mime_type.present?
      if mime_type == 'text/rpm-spec'
        @raw_mime_type = 'text/x-rpm-spec'
      else
        @raw_mime_type = Linguist::Language.detect(name, data).try(:lexer).try(:mimetypes).try(:first)
        @raw_mime_type ||= DEFAULT_MIME_TYPE
        @raw_mime_type.gsub!('application', 'text')
        @raw_mime_type
      end
    end
  end

  class Repo
    def branches_and_tags
      branches + tags # @branches_and_tags ||= # ???
    end

    def diff(a, b, *paths)
      diff = self.git.native('diff', {M: true}, "#{a}...#{b}", '--', *paths)

      if diff =~ /diff --git a/
        diff = diff.sub(/.*?(diff --git a)/m, '\1')
      else
        diff = ''
      end
      Diff.list_from_string(self, diff)
    end

    # The diff stats for the given treeish
    #   git diff --numstat -M a...b
    #
    #   +a+ is the base treeish
    #   +b+ is the head treeish
    #
    # Returns Grit::DiffStat[]
    def diff_stats(a,b)
      stats = []
      Dir.chdir(path) do
        lines = self.git.native(:diff, {numstat: true, M: true}, "#{a}...#{b}").split("\n")
        while !lines.empty?
          files = []
          while lines.first =~ /^([-\d]+)\s+([-\d]+)\s+(.+)/
            additions, deletions, filename = lines.shift.gsub(' => ', '=>').split
            additions, deletions = additions.to_i, deletions.to_i
            stat = DiffStat.new filename, additions, deletions
            stats << stat
          end
        end
        stats
      end
    end
  end
end

Grit::Git.git_timeout = 60
# Grit::Git.git_max_size = 5.megabytes
# Grit.debug = true
GAP_REPO_PATH = '/tmp/gap_repo.git'
unless File.directory? GAP_REPO_PATH
  Grit::Repo.init_bare(GAP_REPO_PATH)
  # FileUtils.chmod "a-w", GAP_REPO_PATH
end
