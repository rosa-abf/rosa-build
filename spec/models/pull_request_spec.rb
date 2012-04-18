# -*- encoding : utf-8 -*-
require 'spec_helper'

describe PullRequest do

  #~ context 'when create with same owner that platform' do
    #~ before (:each) do
      #~ stub_rsync_methods
      #~ @platform = FactoryGirl.create(:platform)
      #~ @params = {:name => 'tst_platform', :description => 'test platform'}
    #~ end

    #~ it 'it should increase Repository.count by 1' do
      #~ rep = Repository.create(@params) {|r| r.platform = @platform}
      #~ @platform.repositories.count.should eql(1)
    #~ end
  #~ end
  
  before(:all) do
    stub_rsync_methods
    Platform.delete_all
    User.delete_all
    Repository.delete_all
    FileUtils.rm_rf(APP_CONFIG['root_path'])
    # Need for validate_uniqueness_of check
    FactoryGirl.create(:pull_request)
  end

  it { should belong_to(:project) }
  it { should have_many(:comments)}
  
  it { should validate_presence_of(:title)}
  #it { should validate_uniqueness_of(:serial_id).scoped_to(:project_id) }
  it { should validate_presence_of(:body) }

  it { should_not allow_mass_assignment_of(:project) }
  it { should_not allow_mass_assignment_of(:project_id) }
  it { should_not allow_mass_assignment_of(:user) }
  it { should_not allow_mass_assignment_of(:user_id) }

  after(:all) do
    Platform.delete_all
    User.delete_all
    Repository.delete_all
    FileUtils.rm_rf(APP_CONFIG['root_path'])
  end

end
