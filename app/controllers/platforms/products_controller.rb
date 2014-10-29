class Platforms::ProductsController < Platforms::BaseController
  include GitHelper
  layout 'bootstrap'

  before_filter :authenticate_user!
  skip_before_filter :authenticate_user!, only: [:index, :show] if APP_CONFIG['anonymous_access']

  load_and_authorize_resource :platform
  load_and_authorize_resource :product, through: :platform, except: :autocomplete_project
  before_filter :set_project, only: [:create, :update]

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
    items = Project.accessible_by(current_ability, :membered)
                   .search(params[:term]).limit(20)
    #items.select! {|e| e.repo.branches.count > 0}
    render json: items.map{ |p|
      {
        id: p.id,
        label: p.name_with_owner,
        value: p.name_with_owner,
        project_versions: versions_for_group_select(p)
      }
    }
  end

  protected

  def set_project
    @product.project = Project.find_by_owner_and_name params[:src_project]
  end
end
