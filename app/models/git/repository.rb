class Git::Repository
  delegate :commits, :tree, :tags, :heads, :to => :repo

  attr_accessor :path, :name

  def initialize(path)
    @path = path
  end

  def master
    commits.first
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

end