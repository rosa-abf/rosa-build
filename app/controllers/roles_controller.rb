class RolesController < ApplicationController
  before_filter :authenticate_user!
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

  def get_dump
    file = Role.save_dump
    send_file file, :type => 'text/plain'
  end

  def load_from_dump
    flag = true
    puts params.inspect
    puts File.extname(params[:file].original_filename)
    unless ['.yml', '.yaml'].include? File.extname(params[:file].original_filename)
      flash[:error] = t("layout.roles.wrong_file_type")
      flag = false
    end
    if flag
      t = YAML.load params[:file].tempfile
      unless t.is_a? Hash and t[:Roles]
        flash[:error] = t("layout.roles.wrong_file_format")
        flag = false
      else
        begin
          Role.all_from_dump! t
          flash[:notice] = t("layout.roles.successful_load")
        rescue
          flash[:error] = t("layout.roles.seeding_fail")
        end
      end
    end
    redirect_to :back
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
