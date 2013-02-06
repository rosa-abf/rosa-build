# -*- encoding : utf-8 -*-
class Api::V1::ProductBuildListsController < Api::V1::BaseController
  before_filter :authenticate_user!
  skip_before_filter :authenticate_user!, :only => [:index, :show] if APP_CONFIG['anonymous_access']

  load_and_authorize_resource :product, :only => :index
  load_and_authorize_resource :product_build_list

  def index
    @product_build_lists = if @product
                             @product.product_build_lists
                           else
                             ProductBuildList.accessible_by current_ability, :read
                           end
    @product_build_lists = @product_build_lists.joins(:product, :project, :arch)
    @product_build_lists = @product_build_lists.recent.paginate(paginate_params)
  end

  def create
    create_subject @product_build_list
  end

  def update
    update_subject @product_build_list
  end

  def show
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
end
