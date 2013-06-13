# -*- encoding : utf-8 -*-
require 'spec_helper'

shared_examples_for 'user with change projects in repository rights' do

  it 'should be able to see add_project page' do
    get :add_project, :id => @repository.id, :platform_id => @platform.id
    response.should render_template(:projects_list)
  end

  it 'should be able to add project to repository' do
    get :add_project, :id => @repository.id, :platform_id => @platform.id, :project_id => @project.id
    response.should redirect_to(platform_repository_path(@repository.platform, @repository))
    @repository.projects.should include(@project)
  end

  it 'should be able to remove project from repository' do
    get :remove_project, :id => @repository.id, :platform_id => @platform.id, :project_id => @project.id
    response.should redirect_to(platform_repository_path(@repository.platform, @repository))
    @repository.projects.should_not include(@project)
  end

end

shared_examples_for 'user without change projects in repository rights' do
  it 'should not be able to add project to repository' do
    get :add_project, :id => @repository.id, :platform_id => @platform.id, :project_id => @project.id
    response.should redirect_to(redirect_path)
    @repository.projects.should_not include(@project)
  end

  it 'should not be able to perform regenerate_metadata action' do
    put :regenerate_metadata, :id => @repository.id, :platform_id => @platform.id
    response.should redirect_to(redirect_path)
  end

  it 'should not be able to remove project from repository' do
    delete :remove_project, :id => @repository.id, :platform_id => @platform.id, :project_id => @project.id
    response.should redirect_to(redirect_path)
    @repository.projects.should_not include(@project)
  end
end

shared_examples_for 'registered user or guest' do
  it 'should not be able to perform new action' do
    get :new, :platform_id => @platform.id
    response.should redirect_to(redirect_path)
  end

  it 'should not be able to perform regenerate_metadata action' do
    put :regenerate_metadata, :id => @repository.id, :platform_id => @platform.id
    response.should redirect_to(redirect_path)
    @redis_instance.lrange(AbfWorker::BuildListsPublishTaskManager::REGENERATE_METADATA, 0, -1)
      .should be_empty
  end

  it 'should not be able to perform create action' do
    post :create, @create_params
    lambda { post :create, @create_params }.should change{ Repository.count }.by(0)
    response.should redirect_to(redirect_path)
  end

  it 'should not be able to perform edit action' do
    get :edit, :id => @repository.id, :platform_id => @platform.id
    response.should redirect_to(redirect_path)
  end

  it 'should not be able to perform update action' do
    put :update, :id => @repository.id, :platform_id => @platform.id
    response.should redirect_to(redirect_path)
  end

  it 'should not be able to add new member to repository' do
    post :add_member, :id => @repository.id, :platform_id => @platform.id, :member_id => @another_user.id
    response.should redirect_to(redirect_path)
    @repository.members.should_not include(@another_user)
  end

  it 'should not be able to remove member from repository' do
    @repository.relations.create(:role => 'admin', :actor => @another_user)
    delete :remove_member, :id => @repository.id, :platform_id => @platform.id, :member_id => @another_user.id
    response.should redirect_to(redirect_path)
    @repository.members.should include(@another_user)
  end

  it 'should not be able to remove members from repository' do
    another_user2 = FactoryGirl.create(:user)
    @repository.relations.create(:role => 'admin', :actor => @another_user)
    @repository.relations.create(:role => 'admin', :actor => another_user2)
    post :remove_members, :id => @repository.id, :platform_id => @platform.id,
      :user_remove => {@another_user.id => [1], another_user2.id => [1]}
    response.should redirect_to(redirect_path)
    @repository.members.should include(@another_user, another_user2)
  end

  it 'should not be able to destroy repository in main platform' do
    delete :destroy, :id => @repository.id, :platform_id => @platform.id
    response.should redirect_to(redirect_path)
    lambda { delete :destroy, :id => @repository.id }.should_not change{ Repository.count }.by(-1)
  end

  it 'should not be able to destroy personal repository' do
    lambda { delete :destroy, :id => @personal_repository.id, :platform_id => @personal_repository.platform.id}.
      should change{ Repository.count }.by(0)
    response.should redirect_to(redirect_path)
  end
end

shared_examples_for 'registered user' do
  it 'should be able to perform index action' do
    get :index, :platform_id => @platform.id
    response.should render_template(:index)
  end

  it 'should be able to perform show action' do
    get :show, :id => @repository.id
    response.should render_template(:show)
  end

  it 'should be able to perform projects_list action' do
    get :projects_list, :id => @repository.id, :platform_id => @platform.id, :format => :json
    response.should be_success
  end

end

shared_examples_for 'platform admin user' do
  
  it_should_behave_like 'registered user'

  it 'should be able to perform new action' do
    get :new, :platform_id => @platform.id
    response.should render_template(:new)
  end

  it 'should be able to perform regenerate_metadata action' do
    put :regenerate_metadata, :id => @repository.id, :platform_id => @platform.id
    response.should redirect_to(platform_repository_path(@platform, @repository))
    @redis_instance.lrange(AbfWorker::BuildListsPublishTaskManager::REGENERATE_METADATA, 0, -1)
      .should == ["#{@repository.id}-#{@platform.id}"]
  end

  it 'should be able to create repository' do
    lambda { post :create, @create_params }.should change{ Repository.count }.by(1)
    response.should redirect_to(platform_repository_path(@platform, Repository.last))
  end
  
  it 'should be able to destroy repository in main platform' do
    lambda { delete :destroy, :id => @repository.id, :platform_id => @platform.id }.should change{ Repository.count }.by(-1)
    response.should redirect_to(platform_repositories_path(@repository.platform))
  end

  it 'should be able to perform edit action' do
    get :edit, :id => @repository.id, :platform_id => @platform.id
    response.should render_template(:edit)
  end

  it 'should be able to add new member to repository' do
    post :add_member, :id => @repository.id, :platform_id => @platform.id, :member_id => @another_user.id
    response.should redirect_to(edit_platform_repository_path(@repository.platform, @repository))
    @repository.members.should include(@another_user)
  end

  it 'should be able to remove member from repository' do
    @repository.relations.create(:role => 'admin', :actor => @another_user)
    delete :remove_member, :id => @repository.id, :platform_id => @platform.id, :member_id => @another_user.id
    response.should redirect_to(edit_platform_repository_path(@repository.platform, @repository))
    @repository.members.should_not include(@another_user)
  end

  it 'should be able to remove members from repository' do
    another_user2 = FactoryGirl.create(:user)
    @repository.relations.create(:role => 'admin', :actor => @another_user)
    @repository.relations.create(:role => 'admin', :actor => another_user2)
    post :remove_members, :id => @repository.id, :platform_id => @platform.id,
      :user_remove => {@another_user.id => [1], another_user2.id => [1]}
    response.should redirect_to(edit_platform_repository_path(@repository.platform, @repository))
    @repository.members.should_not include(@another_user, another_user2)
  end

  it 'should not be able to destroy personal repository with name "main"' do
    # hook for "ActiveRecord::ActiveRecordError: name is marked as readonly"
    Repository.where(:id => @personal_repository.id).update_all("name = 'main'")
    lambda { delete :destroy, :id => @personal_repository.id, :platform_id => @personal_repository.platform.id}.
      should change{ Repository.count }.by(0)
    response.should redirect_to(forbidden_path)
  end

  it 'should be able to destroy personal repository with name not "main"' do
    lambda { delete :destroy, :id => @personal_repository.id, :platform_id => @personal_repository.platform.id}.
      should change{ Repository.count }.by(-1)
    response.should redirect_to(platform_repositories_path(@personal_repository.platform))
  end

  it_should_behave_like 'user with change projects in repository rights'
end

describe Platforms::RepositoriesController do
  before(:each) do
    stub_symlink_methods
    stub_redis

    @platform = FactoryGirl.create(:platform)
    @repository = FactoryGirl.create(:repository, :platform =>  @platform)
    @personal_repository = FactoryGirl.create(:personal_repository)
    @project = FactoryGirl.create(:project)
    @another_user = FactoryGirl.create(:user)
    @create_params = {:repository => {:name => 'pro', :description => 'pro2'}, :platform_id => @platform.id}

    @user = FactoryGirl.create(:user)
    set_session_for(@user)
  end

  context 'for guest' do

    before(:each) do
      set_session_for(User.new)
    end

    it_should_behave_like 'registered user' if APP_CONFIG['anonymous_access']

    let(:redirect_path) { new_user_session_path }
    it_should_behave_like 'registered user or guest'
    it_should_behave_like 'user without change projects in repository rights'
    
    it "should not be able to perform show action", :anonymous_access => false do
      get :show, :id => @repository
      response.should redirect_to(new_user_session_path)
    end

    it "should not be able to perform index action", :anonymous_access => false do
      get :index, :platform_id => @platform
      response.should redirect_to(new_user_session_path)
    end

    it 'should not be able to perform projects_list action', :anonymous_access => false do
      get :projects_list, :id => @repository.id, :platform_id => @platform.id, :format => :json
      response.response_code.should == 401
    end
    
  end

  context 'for user' do
    it_should_behave_like 'registered user'

    let(:redirect_path) { forbidden_path }
    it_should_behave_like 'registered user or guest'
    it_should_behave_like 'user without change projects in repository rights'
  end

  context 'for admin' do
    before(:each) do
      @user.role = "admin"
      @user.save
    end

    it_should_behave_like 'platform admin user'
    
  end

  context 'for platform owner user' do
    before(:each) do
      @user = @repository.platform.owner
      platform = @personal_repository.platform
      platform.owner = @user; platform.save
      set_session_for(@user)
    end

    it_should_behave_like 'platform admin user'
  end

  context 'for platform member user' do
    before(:each) do
      [@repository, @personal_repository].each do |repo|
        repo.platform.relations.create!(:actor_type => 'User', :actor_id => @user.id, :role => 'admin')
      end
    end

    it_should_behave_like 'platform admin user'
  end

  context 'for repository member user' do
    before(:each) do
      [@repository, @personal_repository].each do |repo|
        repo.relations.create!(:actor_type => 'User', :actor_id => @user.id, :role => 'admin')
      end
    end

    it_should_behave_like 'registered user'

    let(:redirect_path) { forbidden_path }
    it_should_behave_like 'registered user or guest'
    it_should_behave_like 'user with change projects in repository rights'
  end

end
