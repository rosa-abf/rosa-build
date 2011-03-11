class Project < ActiveRecord::Base
  belongs_to :repository

  validate :name, :uniqueness => true, :presence => true, :allow_nil => false, :allow_blank => false
  validate :unixname, :uniqueness => true, :presence => true, :format => { :with => /^[a-zA-Z0-9\-.]+$/ }, :allow_nil => false, :allow_blank => false

  include Project::HasRepository

  before_create :create_directory

  # Redefining a method from Project::HasRepository module to reflect current situation
  def git_repo_path
    @git_repo_path ||= File.join(path, unixname + ".git")
  end

  def path
    build_path(unixname)
  end

  def clone
    p = Project.new
    p.name = name
    p.unixname = unixname
    return p
  end

  protected

    def build_path(dir)
      File.join(repository.path, dir)
    end

    #TODO: Spec me
    def create_directory
      exists = File.exists?(path) && File.directory?(path)
      raise "Directory #{path} already exists" if exists
      if new_record?
        FileUtils.mkdir_p(path)
      elsif unixname_changed?
        FileUtils.mv(build_path(unixname_was), buildpath(unixname))
      end 
    end
end
