class Git::Repository
  delegate :commits, :commit, :tree, :tags, :heads, :commit_count, :log, :branches, :to => :repo

  attr_accessor :path, :name

  def initialize(path)
    @path = path
  end

  def master
    commits('master', 1).first
  end
  
  def to_s
    name
  end

  def repo
    @repo ||= Grit::Repo.new(path)
  end

  def self.create(path)
    repo = Grit::Repo.init_bare(path)
    repo.enable_daemon_serve
  end

  def paginate_commits(treeish, options = {})
    options[:page] = 1 unless options[:page].present?
    options[:page] = options[:page].to_i

    options[:per_page] = 20 unless options[:per_page].present?
    options[:per_page] = options[:per_page].to_i

    skip = options[:per_page] * (options[:page] - 1)
    last_page = (skip + options[:per_page]) >= commit_count(treeish)

    [commits(treeish, options[:per_page], skip), options[:page], last_page]
  end

end