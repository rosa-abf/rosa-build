class ProjectToRepository < ActiveRecord::Base
  belongs_to :project
  belongs_to :repository

  before_save :create_link
  after_destroy :remove_link
  
  after_create lambda {
    project.xml_rpc_create
  }

  def path
    build_path(project.unixname)
  end

  protected

    def build_path(dir)
      File.join(repository.path, dir)
    end

    def create_link
      exists = File.exists?(path) && File.directory?(path)
      raise "Symlink #{path} already exists" if exists
      if new_record?
        FileUtils.ln_s(project.path, path)
      end
    end

    def remove_link
      exists = File.exists?(path) && File.directory?(path)
      raise "Directory #{path} didn't exists" unless exists
      FileUtils.rm_rf(path)
    end

end
