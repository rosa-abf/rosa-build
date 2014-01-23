class Api::V1::ProductsController < Api::V1::BaseController
  before_filter :authenticate_user!
  skip_before_filter :authenticate_user!, only: [:index, :show] if APP_CONFIG['anonymous_access']

  load_and_authorize_resource

  def create
    create_subject @product
  end

  def update
    update_subject @product
  end

  def show
  end

  def destroy
    destroy_subject @product
  end
end
