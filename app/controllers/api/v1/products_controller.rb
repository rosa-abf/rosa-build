class Api::V1::ProductsController < Api::V1::BaseController
  before_action :authenticate_user!
  skip_before_action :authenticate_user!, only: [:index, :show] if APP_CONFIG['anonymous_access']

  before_action :load_product, except: :create

  def create
    create_subject @product = Product.new(subject_params(Product))
  end

  def update
    update_subject @product
  end

  def show
  end

  def destroy
    destroy_subject @product
  end

  private

  # Private: before_action hook which loads Product.
  def load_product
    authorize @product = Product.find(params[:id])
  end

end
