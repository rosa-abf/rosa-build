require 'spec_helper'

describe Platform do
  before { stub_symlink_methods }

  context 'ensures that validations and associations exist' do
    before do
      # Need for validate_uniqueness_of check
      FactoryGirl.create(:platform)
    end

    it { should belong_to(:owner) }
    it { should have_many(:members)}
    it { should have_many(:repositories)}
    it { should have_many(:products)}

    it { should validate_presence_of(:name)}
    it { should validate_uniqueness_of(:name).case_insensitive }
    it { should allow_value('Basic_platform-name-1234').for(:name) }
    it { should_not allow_value('.!').for(:name) }
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
  end

  it 'ensures that folder of platform will be removed after destroy' do
    platform = FactoryGirl.create :platform
    FileUtils.mkdir_p platform.path
    platform.destroy
    Dir.exists?(platform.path).should be_false
  end

  it 'ensures that owner of personal platform can not be changed' do
    platform = FactoryGirl.create :personal_platform
    owner = platform.owner
    platform.owner = FactoryGirl.create :user
    platform.save.should be_false
  end

  it 'ensures that owner of platform of group can not be changed' do
    group = FactoryGirl.create :group
    platform = FactoryGirl.create :personal_platform, owner: group
    platform.owner = FactoryGirl.create :user
    platform.save.should be_false
  end

  it 'ensures that owner of main platform can be changed' do
    platform = FactoryGirl.create :platform
    platform.owner = FactoryGirl.create :user
    platform.save.should be_true
  end

end
