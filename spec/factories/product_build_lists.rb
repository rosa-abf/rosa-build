# -*- encoding : utf-8 -*-
FactoryGirl.define do
  factory :product_build_list do
    association :product, :factory => :product
    association :arch, :factory => :arch
    project { |pbl| pbl.product.project }
    status 0 # BUILD_COMPLETED
    main_script 'build.sh'
    params 'ENV=i586'
    time_living 150
    project_version 'master'

    # see: before_validation in ProductBuildList model
    before(:create) { Arch.find_or_create_by_name('x86_64') }
  end
end
