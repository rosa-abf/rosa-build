class ProjectToRepository < ActiveRecord::Base
  belongs_to :project
  belongs_to :repository
  
  delegate :path, :to => :project

  #before_save :create_link
  before_save :add_compability_link
  #after_destroy :remove_link
  after_destroy :remove_compability_link
  
  after_create lambda {
    project.xml_rpc_create
  }

  #def path
  #  build_path(project.unixname)
  #end
  
  # This is symbolink to /git_projects/<owner.uname>/<unixname>.git
  def sym_path
    "#{ repository.platform.path }/projects/#{ project.unixname }.git"
  end

  protected

    #def build_path(dir)
    #  File.join(repository.path, dir)
    #end

    #def create_link
    #  exists = File.exists?(path) && File.directory?(path)
    #  raise "Symlink #{path} already exists" if exists
    #  if new_record?
    #    FileUtils.ln_s(project.path, path)
    #  end
    #end
    #
    #def remove_link
    #  exists = File.exists?(path) && File.directory?(path)
    #  raise "Directory #{path} didn't exists" unless exists
    #  FileUtils.rm_rf(path)
    #end
    
    def add_compability_link
      exists = File.exists?(sym_path) && File.directory?(sym_path)
      return false if exists
      if new_record?
        #FileUtils.ln_s(path, sym_path)
        system("sudo ln -s #{ path } #{ sym_path }")
      end
    end

    def remove_compability_link
      exists = File.exists?(sym_path) && File.directory?(sym_path)
      return false unless exists
      #FileUtils.rm_rf(sym_path)
      system("sudo rm -rf #{ sym_path }")
    end
end
