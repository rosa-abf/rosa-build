require 'spec_helper'

describe Platform do
  before { stub_symlink_methods }

  context 'ensures that validations and associations exist' do
    it { should belong_to(:owner) }
    it { should have_many(:members)}
    it { should have_many(:repositories)}
    it { should have_many(:products)}

    it { should validate_presence_of(:name)}

    context 'validates uniqueness' do
      before { FactoryGirl.create(:platform) }
      it { should validate_uniqueness_of(:name).case_insensitive }
    end

    it { should allow_value('Basic_platform-name-1234').for(:name) }
    it { should_not allow_value('.!').for(:name) }
    it { should validate_presence_of(:default_branch)}
    it { should validate_presence_of(:description) }
    it { should validate_presence_of(:distrib_type) }
    it { should validate_presence_of(:visibility) }

    Platform::VISIBILITIES.each do |value|
      it {should allow_value(value).for(:visibility)}
    end
    it { should_not allow_value('custom_status').for(:visibility) }

    ['', nil] + Platform::AUTOMATIC_METADATA_REGENERATIONS.each do |value|
      it {should allow_value(value).for(:automatic_metadata_regeneration)}
    end
    it { should_not allow_value('custom_status').for(:visibility) }


    it { should have_readonly_attribute(:name) }
    it { should have_readonly_attribute(:distrib_type) }
    it { should have_readonly_attribute(:parent_platform_id) }
    it { should have_readonly_attribute(:platform_type) }

    it { should_not allow_value("How do you do...\nmy_platform").for(:name) }
  end

  it 'ensures that folder of platform will be removed after destroy' do
    platform = FactoryGirl.create :platform
    FileUtils.mkdir_p platform.path
    platform.destroy
    expect(Dir.exists?(platform.path)).to be_falsy
  end

  it 'ensures that owner of personal platform can not be changed' do
    platform = FactoryGirl.create :personal_platform
    owner = platform.owner
    platform.owner = FactoryGirl.create :user
    expect(platform.save).to be_falsy
  end

  it 'ensures that owner of platform of group can not be changed' do
    group = FactoryGirl.create :group
    platform = FactoryGirl.create :personal_platform, owner: group
    platform.owner = FactoryGirl.create :user
    expect(platform.save).to be_falsy
  end

  it 'ensures that owner of main platform can be changed' do
    platform = FactoryGirl.create :platform
    platform.owner = FactoryGirl.create :user
    expect(platform.save).to be_truthy
  end

end
