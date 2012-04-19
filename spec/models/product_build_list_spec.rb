# -*- encoding : utf-8 -*-
require 'spec_helper'

describe ProductBuildList do
  before(:all) do
    stub_rsync_methods
  end

  it { should belong_to(:product) }

  it { should validate_presence_of(:product_id)}
  it { should validate_presence_of(:status)}

  ProductBuildList::STATUSES.each do |value|
    it {should allow_value(value).for(:status)}
  end

  it {should_not allow_value(555).for(:status)}

  it { should have_readonly_attribute(:product_id) }
  it { should_not allow_mass_assignment_of(:product_id) }

  it { should allow_mass_assignment_of(:status) }
  it { should allow_mass_assignment_of(:notified_at) }
  it { should allow_mass_assignment_of(:base_url) }
  
end
