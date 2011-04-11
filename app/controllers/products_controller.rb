class ProductsController < ApplicationController
  before_filter :authenticate_user!, :except => [:product_begin, :product_end]
  before_filter :find_product_by_name, :only => [:product_begin, :product_end]

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

  protected

    def find_product_by_name
      @product = Product.find_by_name params[:product_name]
    end
end
