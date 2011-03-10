class Project < ActiveRecord::Base
  belongs_to :platform

  validate :name, :uniqueness => true, :presence => true, :allow_nil => false, :allow_blank => false
  validate :unixname, :uniqueness => true, :presence => true, :format => { :with => /^[a-zA-Z0-9\-.]+$/ }, :allow_nil => false, :allow_blank => false

  before_validation :generate_unixname

  include Project::HasRepository

  # Redefining a method from Project::HasRepository module to reflect current situation
  def git_repo_path
    @git_repo_path ||= File.join(APP_CONFIG['root_path'], platform.unixname, unixname, unixname + '.git')
  end

  protected

    def generate_unixname
      self.unixname = name.gsub(/[^a-zA-Z0-9\-.]/, '-')
      #TODO: Fix non-unique unixname
    end
end
