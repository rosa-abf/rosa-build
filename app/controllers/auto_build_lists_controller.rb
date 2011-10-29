class AutoBuildListsController < ApplicationController
  before_filter :authenticate_user!, :except => :auto_build
  
  def index
    @projects_not_automated = Project.scoped
    @projects_not_automated = @projects_not_automated.where(:name => params[:name]) unless params[:name].blank?
    @projects_not_automated = @projects_not_automated.automateable.paginate :page => params[:not_automated_page], :per_page => 15
    
    @projects_already_automated = Project.joins(:auto_build_lists).paginate :page => params[:already_automated_page], :per_page => 15
  end
  
  #def new
  #  @auto_build_list = AutoBuildList.new
  #  # Now user can create auto_build_list only for personal repository and i586 arch.
  #  @bpls = Platform.where(:id => current_user.personal_platform.id)
  #  @pls = Platform.where(:id => current_user.personal_platform.id)
  #  @archs = Arch.where(:name => 'i386')
  #end
  
  def create
    #@auto_build_list = AutoBuildList.new(params[:auto_build_list])
    
    @auto_build_list = AutoBuildList.new(
      :bpl_id => 3, # 'mandriva2011'
      :pl_id => current_user.personal_platform.id,
      :arch_id => Arch.find_by_name('i586').id,
      :project_id => params[:project_id]
    )
    
    if @auto_build_list.save
      redirect_to auto_build_lists_path(), :notice => t('flash.auto_build_list.success')
    else
      #render :action => 'new'
      redirect_to auto_build_lists_path, :notice => t('flash.auto_build_list.failed')
    end
  end
end
