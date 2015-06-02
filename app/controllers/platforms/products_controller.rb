class Platforms::ProductsController < Platforms::BaseController
  include GitHelper

  before_action :authenticate_user!
  skip_before_action :authenticate_user!, only: [:index, :show] if APP_CONFIG['anonymous_access']

  before_action :load_product, except: %i(index new create autocomplete_project)

  def index
    authorize @platform.products.new
    @products = @platform.products.paginate(page: params[:page])
  end

  def new
    authorize @product = @platform.products.new
  end

  def edit
  end

  def create
    authorize @product = @platform.products.build(product_params)
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
    if @product.update_attributes(product_params)
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
    authorize :project
    @items = ProjectPolicy::Scope.new(current_user, Project).membered.
      by_owner_and_name(params[:query]).limit(20)
    #items.select! {|e| e.repo.branches.count > 0}
  end

  private

  def product_params
    subject_params(Product)
  end

  # Private: before_action hook which loads Product.
  def load_product
    authorize @product = Product.find(params[:id])
  end

end
