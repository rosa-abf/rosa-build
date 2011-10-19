class RolesController < ApplicationController
  before_filter :find_role, :only => [:show, :edit, :update, :destroy]

  def index
    @roles = Role.all
  end

  def show
    @permissions = Permission.where(:role_id => @role.id)
  end

  def new
    @role = Role.new
  end

  def edit
  end

  def create
    @role = Role.new(params[:role])
    if @role.save
      for right in params[:right][:id]
        Permission.create(:role_id => @role.id, :right_id => right)
      end
      flash[:notice] = t('flash.role.saved')
      redirect_to roles_path
    else
      flash[:error] = t('flash.role.save_error')
      render :action => :new
    end
  end

  def update
    if @role.update_attributes(params[:role])
      if params[:right][:id]
        Permission.destroy_all(:role_id => @role.id)
        for right in params[:right][:id]
          Permission.create(:role_id => @role.id, :right_id => right)
        end
      end
      flash[:notice] = t('flash.role.saved')
      redirect_to roles_path
    else
      flash[:error] = t('flash.role.save_error')
      render :action => :edit
    end
  end

  def destroy
    @role.destroy
    Permission.destroy_all(:role_id => params[:id])
    flash[:notice] = t("flash.role.destroyed")
    redirect_to roles_path
  end
  
  protected
    def find_role
      @role = Role.find(params[:id])
    end
end