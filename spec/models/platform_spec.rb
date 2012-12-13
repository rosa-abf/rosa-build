# -*- encoding : utf-8 -*-
require 'spec_helper'

describe Platform do
  before(:all) do
    stub_symlink_methods
    Platform.delete_all
    User.delete_all
    init_test_root
    # Need for validate_uniqueness_of check
    FactoryGirl.create(:platform)
  end

  it { should belong_to(:owner) }
  it { should have_many(:members)}
  it { should have_many(:repositories)}
  it { should have_many(:products)}

  it { should validate_presence_of(:name)}
  it { should validate_uniqueness_of(:name).case_insensitive }
  it { should validate_format_of(:name).with('Basic_platform-name-1234') }
  it { should validate_format_of(:name).not_with('.!') }
  it { should validate_presence_of(:description) }
  it { should validate_presence_of(:distrib_type) }
  it { should validate_presence_of(:visibility) }

  Platform::VISIBILITIES.each do |value|
    it {should allow_value(value).for(:visibility)}
  end
  it {should_not allow_value('custom_status').for(:visibility)}

  it { should have_readonly_attribute(:name) }
  it { should have_readonly_attribute(:distrib_type) }
  it { should have_readonly_attribute(:parent_platform_id) }
  it { should have_readonly_attribute(:platform_type) }

  it { should_not allow_mass_assignment_of(:repositories) }
  it { should_not allow_mass_assignment_of(:products) }
  it { should_not allow_mass_assignment_of(:members) }
  it { should_not allow_mass_assignment_of(:parent) }

  it {should_not allow_value("How do you do...\nmy_platform").for(:name)}

  after(:all) do
    Platform.delete_all
    User.delete_all
    clear_test_root
  end
end
