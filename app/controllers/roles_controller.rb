class RolesController < ApplicationController
  before_filter :find_role, :only => [:show, :edit, :update, :destroy]
  before_filter :find_visibilities, :only => [:new, :edit]

  def index
    @roles = Role.all
  end

  def show
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
    puts params[:inspect]
    if @role.update_attributes(params[:role])
      if params[:rights] and params[:rights][:id]
        @role.rights = Right.find(params[:rights][:id])
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

    def find_visibilities
      @visibilities = ActiveRecord::Base.descendants.inject({}) do |h, m|
        if m.public_instance_methods.include? 'visibility'
          begin
            h[m.name] = m::VISIBILITIES
          rescue
            nil
          end
        end
        h
      end
    end
end
