# -*- encoding : utf-8 -*-
Factory.define(:product_build_list) do |p|
  p.association :product, :factory => :product
end
