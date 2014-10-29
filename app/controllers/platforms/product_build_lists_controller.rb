class Platforms::ProductBuildListsController < Platforms::BaseController
  include FileStoreHelper
  layout 'bootstrap'

  before_filter :authenticate_user!
  skip_before_filter :authenticate_user!, only: [:index, :show, :log] if APP_CONFIG['anonymous_access']
  before_filter :redirect_to_full_path_if_short_url, only: [:show, :update]
  load_and_authorize_resource :platform, except: :index
  load_and_authorize_resource :product, through: :platform, except: :index
  load_and_authorize_resource :product_build_list, through: :product, except: :index
  load_and_authorize_resource only: [:index, :show, :log, :cancel, :update]

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

  def update
    @product_build_list.update_attributes(not_delete: (params[:product_build_list] || {})[:not_delete])
    render :show
  end

  def cancel
    if @product_build_list.cancel
      notice = t('layout.build_lists.will_be_canceled')
    else
      notice = t('layout.build_lists.cancel_fail')
    end
    redirect_to :back, notice: notice
  end

  def log
    worker_log = @product_build_list.abf_worker_log

    render json: {
      log: ( Pygments.highlight(worker_log, lexer: 'sh') rescue worker_log),
      building: @product_build_list.build_started?
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
      render action: :new
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
    @product_build_list = ProductBuildList.new(params[:product_build_list])
    @product_build_list.status = nil if params[:product_build_list].blank?
    if @product_build_list.product_id.present?
      @product_build_lists = @product_build_lists.where(id: @product_build_list.product_id)
    else
      @product_build_lists = @product_build_lists.
        scoped_to_product_name(@product_build_list.product_name).
        for_status(@product_build_list.status)
    end
    @product_build_lists = @product_build_lists.recent.paginate page: params[:page]
    @build_server_status = AbfWorkerStatusPresenter.new.products_status
  end

  protected

  def redirect_to_full_path_if_short_url
    if params[:platform_id].blank? || params[:product_id].blank?
      pbl               = ProductBuildList.find params[:id]
      product, platform = pbl.product, pbl.product.platform
      redirect_to platform_product_product_build_list_path(platform, product, pbl)
    end
  end

end
