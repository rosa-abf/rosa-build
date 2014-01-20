require 'spec_helper'

shared_examples_for 'mass_build platform owner' do
  it 'should be able to perform index action' do
    get :index, :platform_id => @platform
    response.should render_template(:index)
  end

  it 'should be able to perform new action' do
    get :new, :platform_id => @platform
    response.should render_template(:new)
  end

  it 'should be able to perform create action' do
    post :create, @create_params
    response.should redirect_to(platform_mass_builds_path(@platform))
  end

  it 'should be able to perform cancel action' do
    post :cancel, :platform_id => @platform, :id => @mass_build
    response.should redirect_to(platform_mass_builds_path(@platform))
  end

  it 'should change stop_build on cancel' do
    post :cancel, :platform_id => @platform, :id => @mass_build
    @mass_build.reload.stop_build.should == true
  end

  it 'should be able to perform publish action' do
    post :publish, :platform_id => @platform, :id => @mass_build
    response.should redirect_to(platform_mass_builds_path(@platform))
  end

  it 'should change build_publish on publish' do
    post :publish, :platform_id => @platform, :id => @mass_build
    @mass_build.reload.build_publish_count.should == 1
  end

  it 'should not be able to perform cancel action if stop_build is true' do
    @mass_build.stop_build = true; @mass_build.save
    post :cancel, :platform_id => @platform, :id => @mass_build
    response.should redirect_to(forbidden_path)
  end

  it 'should change objects count on create success' do
    lambda { post :create, @create_params }.should change{ MassBuild.count }.by(1)
  end

  it 'should be able to perform get_list action' do
    get :get_list, :platform_id => @platform, :id => @mass_build, :kind => 'failed_builds_list'
    response.should be_success
  end
end

shared_examples_for 'mass_build platform owner of personal platform' do
  before(:each) do
    Platform.update_all(:platform_type => 'personal')
    repository = FactoryGirl.create(:repository)
    @mass_build.build_lists.each do |bl|
      bl.build_for_platform = repository.platform
      bl.include_repos      = [repository.id]
      bl.save
    end
  end
  it_should_behave_like 'mass_build platform owner'
end

shared_examples_for 'mass_build platform reader' do
  it 'should be able to perform index action' do
    get :index, :platform_id => @platform
    response.should render_template(:index)
  end

  it 'should be able to perform get_list action' do
    get :get_list, :platform_id => @platform, :id => @mass_build, :kind => 'failed_builds_list'
    response.should be_success
  end

  it "should not be able to perform new action" do
    get :new, :platform_id => @platform
    response.should redirect_to(forbidden_path)
  end

  it "should not be able to perform create action" do
    get :create, :platform_id => @platform
    response.should redirect_to(forbidden_path)
  end

  [:cancel, :publish].each do |action|
    it "should not be able to perform #{ action } action" do
      get action, :platform_id => @platform, :id => @mass_build.id
      response.should redirect_to(forbidden_path)
    end
  end

  it 'should not change objects count on create success' do
    lambda { post :create, @create_params }.should change{ MassBuild.count }.by(0)
  end

  it 'should not change stop_build on cancel' do
    post :cancel, :platform_id => @platform, :id => @mass_build
    @mass_build.reload.stop_build.should == false
  end

  it 'should not change build_publish on publish' do
    post :publish, :platform_id => @platform, :id => @mass_build
    @mass_build.reload.build_publish_count.should == 0
  end
end


describe Platforms::MassBuildsController do
  before(:each) do
    stub_symlink_methods

    FactoryGirl.create(:arch)
    @platform = FactoryGirl.create(:platform)
    @repository = FactoryGirl.create(:repository, :platform => @platform)
    @personal_platform = FactoryGirl.create(:platform, :platform_type => 'personal')
    @user = FactoryGirl.create(:user)
    project = FactoryGirl.create(:project, :owner => @user)
    @repository.projects << project

    @create_params = {
      :mass_build => {
        :projects_list          => @repository.projects.map(&:name).join("\n"),
        :auto_publish           => true,
        :build_for_platform_id  => @platform
      },
      :platform_id  => @platform,
      :arches               => [Arch.first.id],
    }

    @mass_build = FactoryGirl.create(:mass_build, :save_to_platform => @platform, :user => @user, :projects_list => project.name)
    FactoryGirl.create(:build_list, :mass_build => @mass_build, :status => BuildList::SUCCESS)
  end

  context 'for guest' do

    it 'should be able to perform index action', :anonymous_access => true do
      get :index, :platform_id => @platform
      response.should render_template(:index)
    end

    it 'should not be able to perform index action', :anonymous_access => false do
      get :index, :platform_id => @platform
      response.should redirect_to(new_user_session_path)
    end

    it 'should be able to perform get_list action', :anonymous_access => true do
      get :get_list, :platform_id => @platform, :id => @mass_build, :kind => 'failed_builds_list'
      response.should be_success
    end

    it "should not be able to get failed builds list", :anonymous_access => false do
      get :get_list, :platform_id => @platform, :id => @mass_build, :kind => 'failed_builds_list'
      response.should redirect_to(new_user_session_path)
    end

    it "should not be able to perform new action" do
      get :new, :platform_id => @platform
      response.should redirect_to(new_user_session_path)
    end

    [:cancel, :publish, :create].each do |action|
      it "should not be able to perform #{action} action" do
        post action, :platform_id => @platform, :id => @mass_build
        response.should redirect_to(new_user_session_path)
      end
    end

    it 'should not change objects count on create success' do
      lambda { post :create, @create_params }.should change{ MassBuild.count }.by(0)
    end

    it 'should not change stop_build on cancel' do
      post :cancel, :platform_id => @platform, :id => @mass_build
      @mass_build.reload.stop_build.should == false
    end

    it 'should not change build_publish_count on publish' do
      post :publish, :platform_id => @platform, :id => @mass_build
      @mass_build.reload.build_publish_count.should == 0
    end

  end

  context 'for global admin' do
    before(:each) do
      @admin = FactoryGirl.create(:admin)
      @user = FactoryGirl.create(:user)
      set_session_for(@admin)
    end

    it_should_behave_like 'mass_build platform owner'
    it_should_behave_like 'mass_build platform owner of personal platform'
  end

  context 'for owner user' do
    before(:each) do
      @user = FactoryGirl.create(:user)
      set_session_for(@user)
      
      @platform.owner = @user
      @platform.save
    end

    it_should_behave_like 'mass_build platform owner'
    it_should_behave_like 'mass_build platform owner of personal platform'
  end

  context 'for admin user' do
    before(:each) do
      @user = FactoryGirl.create(:user)
      set_session_for(@user)
      @platform.relations.create!(:actor_type => 'User', :actor_id => @user.id, :role => 'admin')
    end

    it_should_behave_like 'mass_build platform owner'
    it_should_behave_like 'mass_build platform owner of personal platform'
  end

  context 'for reader user' do
    before(:each) do
      @user = FactoryGirl.create(:user)
      set_session_for(@user)
      @platform.relations.create!(:actor_type => 'User', :actor_id => @user.id, :role => 'reader')
    end

    it_should_behave_like 'mass_build platform reader'
  end
end
