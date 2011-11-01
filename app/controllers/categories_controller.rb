class CategoriesController < ApplicationController
  before_filter :authenticate_user!
  before_filter :find_category, :only => [:show, :edit, :update, :destroy]
  before_filter :find_platform, :only => [:show, :index]

  before_filter :check_global_access, :only => [:platforms, :new, :create]

  def platforms
    @platforms = Platform.all
    @platforms_count = Platform.joins(:repositories => :projects).group('platforms.id').count
  end

  def index
    if @platform
      can_perform? @platform
      @categories = Category.select('categories.id, categories.name, categories.ancestry, count(projects.id) projects_count').
                             joins(:projects => :repositories).where('repositories.platform_id = ?', @platform.id).
                             having('projects_count > 0').group('categories.id').default_order
      render 'index2'
    else
      @categories = Category.default_order.paginate(:page => params[:page])
    end
  end

  def show
    can_perform? @platform if @platform
    can_perform? @category if @category

    @projects = @category.projects
    @projects = @projects.joins(:repositories).where("repositories.platform_id = ?", @platform.id) if @platform
    @projects = @projects.paginate :page => params[:page]
  end

  def new
    @category = Category.new
  end

  def edit
    can_perform? @category if @category
  end

  def destroy
    can_perform? @category if @category
    @category.destroy
    flash[:notice] = t("flash.category.destroyed")
    redirect_to categories_path
  end

  def create
    @category = Category.new params[:category]
    if @category.save
      flash[:notice] = t('flash.category.saved')
      redirect_to categories_path
    else
      flash[:error] = t('flash.category.save_error')
      render :action => :new
    end
  end

  def update
    can_perform? @category if @category
    if @category.update_attributes(params[:category])
      flash[:notice] = t('flash.category.saved')
      redirect_to categories_path
    else
      flash[:error] = t('flash.category.save_error')
      render :action => :edit
    end
  end

  protected

  def find_category
    @category = Category.find(params[:id])
  end

  def find_platform
    @platform = Platform.find(params[:platform_id]) if params[:platform_id]
  end
end
