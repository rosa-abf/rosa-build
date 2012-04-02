# -*- encoding : utf-8 -*-
require 'spec_helper'

describe Repository do

  context 'when create with same owner that platform' do
    before (:each) do
      stub_rsync_methods
      @platform = FactoryGirl.create(:platform)
      @params = {:name => 'tst_platform', :description => 'test platform'}
    end

    it 'it should increase Repository.count by 1' do
      rep = Repository.create(@params) {|r| r.platform = @platform}
      @platform.repositories.count.should eql(1)
    end
  end
  
  before(:all) do
    stub_rsync_methods
    Platform.delete_all
    User.delete_all
    Repository.delete_all
    FileUtils.rm_rf(APP_CONFIG['root_path'])
    # Need for validate_uniqueness_of check
    FactoryGirl.create(:repository)
  end
  
  it { should belong_to(:platform) }
  it { should have_many(:project_to_repositories)}
  it { should have_many(:projects).through(:project_to_repositories)}
  
  it { should validate_presence_of(:name)}
  it { should validate_uniqueness_of(:name).case_insensitive.scoped_to(:platform_id) }
  it { should validate_format_of(:name).with('basic_repository-name-1234') }
  it { should validate_format_of(:name).not_with('.!') }
  it { should validate_format_of(:name).not_with('Main') }
  it { should validate_presence_of(:description) }
  
  it { should have_readonly_attribute(:name) }
  it { should have_readonly_attribute(:platform_id) }
  
  it { should_not allow_mass_assignment_of(:platform) }
  it { should_not allow_mass_assignment_of(:platform_id) }
  
  after(:all) do
    Platform.delete_all
    User.delete_all
    Repository.delete_all
    FileUtils.rm_rf(APP_CONFIG['root_path'])
  end
  
end
