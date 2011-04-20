module Project::HasRepository

  def self.included(model)
  end

  def git_repository
    @git_repository ||= Git::Repository.new(git_repo_path)
  end

  protected
    def git_repo_path
      @git_repo_path ||= File.join(APP_CONFIG['root_path'], platform.unixname, project.unixname, project.unixname + '.git')
    end
end
