class ProductsController < ApplicationController
  before_filter :authenticate_user!
  before_filter :find_product, :only => [:show, :edit, :update, :destroy]
  before_filter :find_platform

  authorize_resource

  def new
    @product = @platform.products.new
    @product.ks = DEFAULT_KS
    @product.menu = DEFAULT_MENU
    @product.counter = DEFAULT_COUNTER
    @product.build_script = DEFAULT_BUILD
  end

  # def clone
  #   @template = @platform.products.find(params[:id])
  #   @product = @platform.products.new
  #   @product.clone_from!(@template)
  # 
  #   render :template => "products/new"
  # end

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

  def destroy
    @product.destroy
    flash[:notice] = t("flash.product.destroyed")
    redirect_to @platform
  end

  protected

    def find_product
      @product = Product.find params[:id]
    end

    def find_platform
      @platform = Platform.find params[:platform_id]
    end
end
