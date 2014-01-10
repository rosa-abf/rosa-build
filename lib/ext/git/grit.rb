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

    # def file_mime_type
    #   @file_mime_type ||= data.file_type(:mime_type)
    # end
    #
    # def text?
    #   file_mime_type =~ /^text\// # not binary?
    # end
    #
    # def binary?
    #   not text? # file_mime_type !~ /^text\//
    #   # s = data.split(//); ((s.size - s.grep(" ".."~").size) / s.size.to_f) > 0.30 # works only for latin chars
    # end
    #
    # def image?
    #   mime_type.match(/image/)
    # end

    DEFAULT_RAW_MIME_TYPE = MIME::Types[DEFAULT_MIME_TYPE].first

    def mime_type_with_class_store
      set_associated_mimes
      @associated_mimes.first.simplified
    end
    alias_method_chain :mime_type, :class_store

    attr_accessor :raw_mime_type
    def raw_mime_type
      set_associated_mimes
      @raw_mime_type = @associated_mimes.first || DEFAULT_RAW_MIME_TYPE
      @raw_mime_type
    end

    def raw_mime_types
      set_associated_mimes
    end

    protected

    # store all associated MIME::Types inside class
    def set_associated_mimes
      @associated_mimes ||= []
      if @associated_mimes.empty?
        guesses = MIME::Types.type_for(self.name) rescue [DEFAULT_RAW_MIME_TYPE]
        guesses = [DEFAULT_RAW_MIME_TYPE] if guesses.empty?

        @associated_mimes = guesses.sort{|a,b| mime_sort(a, b)}
      end
      @associated_mimes
    end

    # TODO make more clever function
    def mime_sort(a,b)
      return 0 if a.media_type == b.media_type and a.registered? == b.registered?
      return -1 if a.media_type == 'text' and !a.registered?
      return 1
    end
  end

  class Repo
    def branches_and_tags
      branches + tags # @branches_and_tags ||= # ???
    end

    def diff(a, b, *paths)
      diff = self.git.native('diff', {:M => true}, "#{a}...#{b}", '--', *paths)

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
        lines = self.git.native(:diff, {:numstat => true, :M => true}, "#{a}...#{b}").split("\n")
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
