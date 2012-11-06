# -*- encoding : utf-8 -*-
class Platforms::ProductBuildListsController < Platforms::BaseController
  before_filter :authenticate_user!, :except => [:status_build]
  skip_before_filter :authenticate_user!, :only => [:index] if APP_CONFIG['anonymous_access']
  load_and_authorize_resource :platform, :only => [:create, :destroy, :new]
  load_and_authorize_resource :product, :through => :platform, :only => [:create, :destroy, :new]
  load_and_authorize_resource :product_build_list, :through => :product, :only => [:create, :destroy, :new]
  load_and_authorize_resource :only => [:index]

  before_filter :authenticate_product_builder!, :only => [:status_build]
  before_filter :find_product_build_list, :only => [:status_build]

  def new
  end

  def create
    @product.product_build_lists.create! :base_url => "http://#{request.host_with_port}"
    flash[:notice] = t('flash.product.build_started')
    redirect_to [@platform, @product]
  end

  def status_build
    @product_build_list.status = params[:status].to_i # ProductBuildList::BUILD_COMPLETED : ProductBuildList::BUILD_FAILED)
    @product_build_list.save!
    render :nothing => true
  end

  def destroy
    if @product_build_list.destroy
      flash[:notice] = t('flash.product_build_list.delete')
     else
      flash[:error] = t('flash.product_build_list.delete_error')
     end 
    redirect_to [@platform, @product]
  end

  def index
    if params[:product_id].present?
      @product_build_lists = @product_build_lists.where(:id => params[:product_id])
    else
      @product_build_lists = @product_build_lists.scoped_to_product_name(params[:product_name]) if params[:product_name].present?
      @product_build_lists = @product_build_lists.for_status(params[:status]) if params[:status].present?
    end
    @product_build_lists = @product_build_lists.recent.paginate :page => params[:page]
  end

  protected

  def find_product_build_list
     @product_build_list = ProductBuildList.find params[:id]
  end

  def authenticate_product_builder!
    # FIXME: Rails(?) interpret the internal IP as 127.0.0.1
    unless (APP_CONFIG['product_builder_ip'].values + ["127.0.0.1"]).include?(request.remote_ip)
      render :nothing => true, :status => 403
    end
  end
end
