class CategoriesController < ApplicationController
  before_filter :authenticate_user!
  before_filter :find_category, :only => [:show, :edit, :update, :destroy]
  before_filter :find_platform, :only => [:show, :index]

  load_and_authorize_resource

  def platforms
    @all_platforms = Platform.all
    @all_platforms_count = Platform.joins(:repositories => :projects).group('platforms.id').count
    @personal_platforms = Platform.personal
    @personal_platforms_count = Platform.personal.joins(:repositories => :projects).group('platforms.id').count
    @main_platforms = Platform.main
    @main_platforms_count = Platform.main.joins(:repositories => :projects).group('platforms.id').count
  end

  def index
    if @platform
      @categories = Category.select('categories.id, categories.name, categories.ancestry, count(projects.id) projects_count').
                             joins(:projects => :repositories).where('repositories.platform_id = ?', @platform.id).
                             having('count(projects.id) > 0').group('categories.id, categories.name, categories.ancestry, projects_count').default_order
      render 'index2'
    else
      @categories = Category.default_order.paginate(:page => params[:page])
    end
  end

  def show
    @projects = @category.projects
    @projects = @projects.joins(:repositories).where("repositories.platform_id = ?", @platform.id) if @platform
    @projects = @projects.paginate :page => params[:page]
  end

  def new
    @category = Category.new
  end

  def edit
  end

  def destroy
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
