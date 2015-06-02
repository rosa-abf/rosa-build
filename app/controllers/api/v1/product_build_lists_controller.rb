class Api::V1::ProductBuildListsController < Api::V1::BaseController
  before_action :authenticate_user!
  skip_before_action :authenticate_user!, only: [:index, :show] if APP_CONFIG['anonymous_access']

  before_action :load_product,            only: :index
  before_action :load_product_build_list, except: [:index, :create]

  def index
    @product_build_lists =
      if @product
        @product.product_build_lists
      else
       PlatformPolicy::Scope.new(current_user, ProductBuildList.joins(product: :platform)).show
      end
    @product_build_lists = @product_build_lists.joins(:product, :project, :arch)
    @product_build_lists = @product_build_lists.recent.paginate(paginate_params)
  end

  def create
    @product_build_list = ProductBuildList.new subject_params(ProductBuildList)
    @product_build_list.project     ||= @product_build_list.try(:product).try(:project)
    @product_build_list.main_script ||= @product_build_list.try(:product).try(:main_script)
    @product_build_list.params      ||= @product_build_list.try(:product).try(:params)
    @product_build_list.time_living ||= @product_build_list.try(:product).try(:time_living)
    create_subject @product_build_list
  end

  def show
  end

  def update
    params[:product_build_list] = {not_delete: (params[:product_build_list] || {})[:not_delete]}
    update_subject @product_build_list
  end

  def destroy
    destroy_subject @product_build_list
  end

  def cancel
    if @product_build_list.try(:can_cancel?) && @product_build_list.cancel
      render_json_response @product_build_list, t("layout.product_build_lists.cancel_success")
    else
      render_validation_error @product_build_list, t("layout.product_build_lists.cancel_fail")
    end
  end

  private

  # Private: before_action hook which loads ProductBuildList.
  def load_product_build_list
    authorize @product_build_list = ProductBuildList.find(params[:id])
  end

  # Private: before_action hook which loads Product.
  def load_product
    authorize @product = Product.find(params[:product_id]), :show? if params[:product_id]
  end
end
