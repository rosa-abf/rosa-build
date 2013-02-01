# -*- encoding : utf-8 -*-
class Platforms::ProductBuildListsController < Platforms::BaseController
  before_filter :authenticate_user!
  skip_before_filter :authenticate_user!, :only => [:index, :show, :log] if APP_CONFIG['anonymous_access']
  load_and_authorize_resource :platform, :except => :index
  load_and_authorize_resource :product, :through => :platform, :except => :index
  load_and_authorize_resource :product_build_list, :through => :product, :except => :index
  load_and_authorize_resource :only => [:index, :show, :log, :cancel]

  def new
    product = @product_build_list.product
    @product_build_list.params = product.params
    @product_build_list.main_script = product.main_script
    @product_build_list.time_living = product.time_living
    @product_build_list.project = product.project
    unless @product_build_list.project
      flash[:error] = t('flash.product_build_list.no_project')
      redirect_to edit_platform_product_path(@platform, @product)
    end
  end

  def show
  end

  def cancel
    if @product_build_list.cancel
      notice = t('layout.build_lists.will_be_canceled')
    else
      notice = t('layout.build_lists.cancel_fail')
    end
    redirect_to :back, :notice => notice
  end

  def log
    render :json => {
      :log => @product_build_list.abf_worker_log,
      :building => @product_build_list.build_started?
    }
  end

  def create
    pbl = @product.product_build_lists.new params[:product_build_list]
    pbl.project = @product.project
    pbl.user = current_user
    pbl.base_url = "http://#{request.host_with_port}"

    if pbl.save
      flash[:notice] = t('flash.product.build_started')
      redirect_to [@platform, @product]
    else
      flash[:error] = t('flash.product.build_error')
      flash[:warning] = pbl.errors.full_messages.join('. ')
      render :action => :new
    end
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
    @build_server_status = AbfWorker::StatusInspector.products_status
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
