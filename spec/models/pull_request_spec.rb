# -*- encoding : utf-8 -*-
require 'spec_helper'

def set_data_for_pull
  @ability = Ability.new(@user)

  @project = FactoryGirl.create(:project, :owner => @user)
  %x(cp -Rf #{Rails.root}/spec/tests.git/* #{@project.path}) # maybe FIXME ?

  @clone_path = File.join(APP_CONFIG['root_path'], 'repo_clone', @project.id.to_s)
  FileUtils.mkdir_p(@clone_path)


  any_instance_of(Project, :versions => ['v1.0', 'v2.0'])
end

describe PullRequest do
  context 'for owner user' do
    before (:all) do
      stub_rsync_methods
      @user = FactoryGirl.create(:user)
      set_data_for_pull
      @pull = @project.pull_requests.new(:title => 'test', :body => 'testing')
      @pull.user = @user
      @pull.data = {:base_branch => 'master', :head_branch => 'non_conflicts'}
      @pull.save
    end

    it 'master should can be merged with non_conflicts branch' do
      @pull.check
      @pull.state.should == 'ready'
    end

    it 'master should not be merged with conflicts branch' do
      @pull.data[:head_branch] = 'conflicts'
      @pull.check
      @pull.state.should == 'blocked'
    end

    it 'should not be merged when already up-to-date branches' do
      @pull.data[:head_branch] = 'master'
      @pull.check
      @pull.state.should == 'already'
    end
  end

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
