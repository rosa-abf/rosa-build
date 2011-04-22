class ProductsController < ApplicationController
  before_filter :authenticate_user!, :except => [:product_begin, :product_end]
  before_filter :find_product_by_name, :only => [:product_begin, :product_end]
  before_filter :find_product, :only => [:show, :edit, :update, :build]
  before_filter :find_platform, :except => [:product_begin, :product_end, :build]

  def product_begin
    @product.build_status = Product::STATUS::BUILDING
    @product.build_path = params[:path]
    @product.save!

    render :nothing => true, :status => 200
  end

  def product_end
    @product.build_status = ((params[:status] == BuildServer::SUCCESS) ? Product::BUILD_COMPLETED : Product::BUILD_FAILED)
    @product.build_path = params[:path]
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
    @template = @platform.products.find(params[:id])
    @product = @platform.products.new
    @product.clone_from!(@template)

    render :template => "products/new"
  end

  def build
    flash[:notice] = t('flash.product.build_started')
    ProductBuilder.create_product @product.name, @product.platform.name, [], [], '', '/var/rosa', []
    redirect_to :action => :show
  end

  def edit
  end

  def create
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
    if @product.update_attributes(params[:product])
      flash[:notice] = t('flash.product.saved')
      redirect_to @platform
    else
      flash[:error] = t('flash.product.save_error')
      render :action => "edit"
    end
  end

  def show
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
