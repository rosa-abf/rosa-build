# -*- encoding : utf-8 -*-
class ProductBuildList::Filter
  def initialize(product, user, options = {})
    @product = product
    @user = user
    set_options(options)
  end

  def find
    product_build_lists =  @product ? @product.product_build_lists : ProductBuildList.scoped

    if @options[:id]
      product_build_lists = product_build_lists.where(:id => @options[:id])
    else
      product_build_lists = product_build_lists.accessible_by(::Ability.new(@user), @options[:ownership].to_sym) if @options[:ownership]
      product_build_lists = product_build_lists.for_status(@options[:status]) if @options[:status]
      product_build_lists = product_build_lists.scoped_to_product_name(@options[:product_name]) if @options[:product_name]
    end

    product_build_lists
  end

  def respond_to?(name)
    return true if @options.has_key?(name)
    super
  end

  def method_missing(name, *args, &block)
    @options.has_key?(name) ? @options[name] : super
  end

  private

  def set_options(options)
    @options = HashWithIndifferentAccess.new(options.reverse_merge({
        :ownership => nil,
        :status => nil,
        :id => nil,
        :product_name => nil
    }))

    @options[:ownership] = @options[:ownership].presence || (@product ? 'index' : 'owned')
    @options[:status] = @options[:status].present? ? @options[:status].to_i : nil
    @options[:id] = @options[:id].presence
    @options[:product_name] = @options[:product_name].presence
  end

  #def build_date_from_params(field_name, params)
  #  if params["#{field_name}(1i)"].present? || params["#{field_name}(2i)"].present? || params["#{field_name}(3i)"].present?
  #    Date.civil((params["#{field_name}(1i)"].presence || Date.today.year).to_i, 
  #               (params["#{field_name}(2i)"].presence || Date.today.month).to_i,
  #               (params["#{field_name}(3i)"].presence || Date.today.day).to_i)
  #  else
  #    nil
  #  end
  #end
end
