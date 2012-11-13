# -*- encoding : utf-8 -*-
FactoryGirl.define do
  factory :product_build_list do
    association :product, :factory => :product
    project { |pbl| pbl.product.project }
    status 0 # BUILD_COMPLETED
    main_script 'build.sh'
    params 'ENV=i586'
    time_living 60
    project_version 'latest_master'
  end
end
