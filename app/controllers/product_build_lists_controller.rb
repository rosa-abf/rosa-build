class ProductBuildListsController < ApplicationController
  before_filter :authenticate_user!, :except => [:status_build]
  before_filter :find_product_build_list, :only => [:status_build]
  before_filter :find_product, :except => [:status_build]
  before_filter :find_platform, :except => [:status_build]
  before_filter :check_global_access, :except => [:status_build]

  # def index
  # end

  def create
    can_perform? @product # if @product
    @product.product_build_lists.create! :base_url => "http://#{request.host_with_port}", :notified_at => Time.current
    flash[:notice] = t('flash.product.build_started')
    redirect_to [@platform, @product]
  end

  def status_build
    @product_build_list.status = params[:status].to_i # ProductBuildList::BUILD_COMPLETED : ProductBuildList::BUILD_FAILED)
    @product_build_list.notified_at = Time.current
    @product_build_list.save!
    render :nothing => true
  end

  protected

    def find_product_build_list
       @product_build_list = ProductBuildList.find params[:id]
    end

    def find_product
      @product = Product.find params[:product_id]
    end

    def find_platform
      @platform = Platform.find params[:platform_id]
    end
end
