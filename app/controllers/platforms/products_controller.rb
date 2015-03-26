class Platforms::ProductsController < Platforms::BaseController
  include GitHelper

  before_action :authenticate_user!
  skip_before_action :authenticate_user!, only: [:index, :show] if APP_CONFIG['anonymous_access']

  load_and_authorize_resource :platform
  load_and_authorize_resource :product, through: :platform, except: :autocomplete_project

  def index
    @products = @products.paginate(page: params[:page])
  end

  def new
    @product = @platform.products.new
  end


  def edit
  end

  def create
    if @product.save
      flash[:notice] = t('flash.product.saved')
      redirect_to platform_product_path(@platform, @product)
    else
      flash[:error] = t('flash.product.save_error')
      flash[:warning] = @product.errors.full_messages.join('. ')
      render action: :new
    end
  end

  def update
    if @product.update_attributes(params[:product])
      flash[:notice] = t('flash.product.saved')
      redirect_to platform_product_path(@platform, @product)
    else
      flash[:error] = t('flash.product.save_error')
      flash[:warning] = @product.errors.full_messages.join('. ')
      render action: "edit"
    end
  end

  def show
    @product_build_lists = @product.product_build_lists.default_order.
      paginate(page: params[:page])
  end

  def destroy
    @product.destroy
    flash[:notice] = t("flash.product.destroyed")
    redirect_to platform_products_path(@platform)
  end

  def autocomplete_project
    @items = ProjectPolicy::Scope.new(current_user, Project).membered.
      by_owner_and_name(params[:query]).limit(20)
    #items.select! {|e| e.repo.branches.count > 0}
  end

end
