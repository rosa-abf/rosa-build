class ProductsController < ApplicationController
  before_filter :authenticate_user!, :except => [:product_status]
  before_filter :find_product, :only => [:show, :edit, :update, :build, :product_status, :destroy]
  before_filter :find_platform, :except => [:product_status, :build]
  before_filter :check_global_access, :except => [:product_status]

  def product_status
    @product.build_status = params[:status] == "0" ? Product::BUILD_COMPLETED : Product::BUILD_FAILED
    @product.save!

    render :nothing => true, :status => 200
  end

  def new
    @product = @platform.products.new
    @product.ks = DEFAULT_KS
    @product.menu = DEFAULT_MENU
    @product.counter = DEFAULT_COUNTER
    @product.build = DEFAULT_BUILD
  end

  def clone
    can_perform? @platform if @platform
    @template = @platform.products.find(params[:id])
    @product = @platform.products.new
    @product.clone_from!(@template)

    render :template => "products/new"
  end

  def build
    can_perform? @product if @product
    flash[:notice] = t('flash.product.build_started')
    ProductBuilder.create_product @product.id, '/var/rosa', @product.ks, @product.menu, @product.build, @product.counter, []
    redirect_to :action => :show
  end

  def edit
    can_perform? @product if @product
    can_perform? @platform if @platform
  end

  def create
    can_perform? @platform if @platform
    @product = @platform.products.new params[:product]
    if @product.save
      flash[:notice] = t('flash.product.saved') 
      redirect_to @platform
    else
      flash[:error] = t('flash.product.save_error')
      render :action => :new
    end
  end

  def update
    can_perform? @platform if @platform
    can_perform? @product if @product
    if @product.update_attributes(params[:product])
      flash[:notice] = t('flash.product.saved')
      redirect_to @platform
    else
      flash[:error] = t('flash.product.save_error')
      render :action => "edit"
    end
  end

  def show
    can_perform? @platform if @platform
    can_perform? @product if @product
  end

  def destroy
    can_perform? @platform if @platform
    can_perform? @product if @product
    @product.destroy
    flash[:notice] = t("flash.product.destroyed")
    redirect_to @platform
  end

  protected

    def find_product_by_name
      @product = Product.find_by_name params[:product_name]
    end

    def find_product
      @product = Product.find params[:id]
    end

    def find_platform
      @platform = Platform.find params[:platform_id]
    end
end
