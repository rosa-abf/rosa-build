module Project::HasRepository

  def self.included(model)
  end

  def git_repository
    @repository ||= Git::Repository(git_repo_path, name)
  end

  protected
    def git_repo_path
      @git_repo_path ||= "xxx"
    end
end