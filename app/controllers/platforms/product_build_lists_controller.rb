class Platforms::ProductBuildListsController < Platforms::BaseController
  include FileStoreHelper

  before_action :authenticate_user!
  skip_before_action :authenticate_user!, only: [:index, :show, :log] if APP_CONFIG['anonymous_access']
  before_action :redirect_to_full_path_if_short_url, only: [:show, :update]

  before_action :load_product,            except: :index
  before_action :load_product_build_list, except: [:index, :new, :create]

  def new
    @product_build_list                 = @product.product_build_lists.new
    @product_build_list.params          = @product.params
    @product_build_list.main_script     = @product.main_script
    @product_build_list.time_living     = @product.time_living
    @product_build_list.project_version = @product.project_version
    @product_build_list.project         = @product.project
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
      log: (Pygments.highlight(worker_log, lexer: 'sh') rescue worker_log),
      building: @product_build_list.build_started?
    }
  end

  def create
    pbl = @product.product_build_lists.new product_build_list_params
    pbl.project = @product.project
    pbl.user = current_user
    pbl.base_url = "http://#{request.host_with_port}"

    authorize pbl
    if pbl.save
      flash[:notice] = t('flash.product.build_started')
      redirect_to [@platform, @product]
    else
      flash[:error] = t('flash.product.build_error')
      @product_build_list = pbl
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
    authorize :product_build_list
    @product_build_list = ProductBuildList.new(product_build_list_params)
    @product_build_list.status = nil if params[:product_build_list].try(:[], :status).blank?
    @product_build_lists   = @platform.product_build_lists if @platform
    @product_build_lists ||= PlatformPolicy::Scope.new(current_user, ProductBuildList.joins(product: :platform)).show
    if @product_build_list.product_id.present?
      @product_build_lists = @product_build_lists.where(id: @product_build_list.product_id)
    else
      @product_build_lists = @product_build_lists.
        scoped_to_product_name(@product_build_list.product_name).
        for_status(@product_build_list.status)
    end
    @product_build_lists = @product_build_lists.
      includes(:project, product: :platform).
      recent.paginate(page: current_page)
    @build_server_status = AbfWorkerStatusPresenter.new.products_status
  end

  protected

  def product_build_list_params
    subject_params(ProductBuildList)
  end

  def redirect_to_full_path_if_short_url
    if params[:platform_id].blank? || params[:product_id].blank?
      pbl               = ProductBuildList.find params[:id]
      product, platform = pbl.product, pbl.product.platform
      redirect_to platform_product_product_build_list_path(platform, product, pbl)
    end
  end

  # Private: before_action hook which loads ProductBuildList.
  def load_product_build_list
    authorize @product_build_list = ProductBuildList.find(params[:id])
  end

  # Private: before_action hook which loads Product.
  def load_product
    authorize @product = Product.find(params[:product_id]), :show? if params[:product_id]
  end

end
