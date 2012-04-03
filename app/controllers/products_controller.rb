# -*- encoding : utf-8 -*-
class ProductsController < ApplicationController
  before_filter :authenticate_user!
 
  load_and_authorize_resource :platform
  load_and_authorize_resource :product, :through => :platform

  def index
    @products = @products.paginate(:page => params[:page])
  end

  def new
    @product = @platform.products.new
    @product.ks = DEFAULT_KS
    @product.menu = DEFAULT_MENU
    @product.counter = DEFAULT_COUNTER
    @product.build_script = DEFAULT_BUILD
  end


  def edit
  end

  def create
    if @product.save
      flash[:notice] = t('flash.product.saved') 
      redirect_to platform_product_path(@platform, @product)
    else
      flash[:error] = t('flash.product.save_error')
      flash[:warning] = @product.errors.full_messages.join('. ')
      render :action => :new
    end
  end

  def update
    if @product.update_attributes(params[:product])
      flash[:notice] = t('flash.product.saved')
      redirect_to platform_product_path(@platform, @product)
    else
      flash[:error] = t('flash.product.save_error')
      flash[:warning] = @product.errors.full_messages.join('. ')
      render :action => "edit"
    end
  end

  def show
  end

  def destroy
    @product.destroy
    flash[:notice] = t("flash.product.destroyed")
    redirect_to platform_products_path(@platform)
  end

end
