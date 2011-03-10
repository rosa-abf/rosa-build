class Git::Repository
  delegate :commits, :tree, :tags, :heads, :to => :repo

  attr_accessor :path, :name

  def initialize(path, name)
    @path = path
    @name = name
  end

  def master
    commits.first
  end

  def to_s
    name
  end

  def repo
    @repo ||= Grit::Repo.new(repo_path)
  end

  protected
    def repo_path
      @repo_path ||= File.join(path, name)
    end

end