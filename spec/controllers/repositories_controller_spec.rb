# -*- encoding : utf-8 -*-
require 'spec_helper'

shared_examples_for 'not destroy personal repository' do
  it 'should not be able to destroy personal repository' do
    lambda { delete :destroy, :id => @personal_repository.id, :platform_id => 
      @personal_repository.platform.id}.should change{ Repository.count }.by(0)
    response.should redirect_to(forbidden_path)
  end
end

shared_examples_for 'user with change projects in repository rights' do
  
  it 'should be able to see add_project page' do
    get :add_project, :id => @repository.id, :platform_id => @platform.id
    response.should render_template(:projects_list)
  end
  
  it 'should be able to add project to repository' do
    get :add_project, :id => @repository.id, :platform_id => @platform.id, :project_id => @project.id
    response.should redirect_to(platform_repository_path(@repository.platform, @repository))
    @repository.projects.should include (@project)
  end
  
  it 'should be able to remove project from repository' do
    get :remove_project, :id => @repository.id, :platform_id => @platform.id, :project_id => @project.id
    response.should redirect_to(platform_repository_path(@repository.platform, @repository))
    @repository.projects.should_not include (@project)
  end
  
end

shared_examples_for 'registered user' do
  it 'should be able to perform index action' do
    get :index
    response.should render_template(:index)
  end

  it 'should be able to perform show action' do
    get :show, :id => @repository.id
    response.should render_template(:show)
  end
end

shared_examples_for 'platform admin user' do
  
  it_should_behave_like 'registered user'

  it 'should be able to perform new action' do
    get :new, :platform_id => @platform.id
    response.should render_template(:new)
  end

  it 'should be able to create repository' do
    lambda { post :create, @create_params }.should change{ Repository.count }.by(1)
    response.should redirect_to(platform_repository_path(@platform, Repository.last))
  end
  
  it 'should be able to destroy repository in main platform' do
    lambda { delete :destroy, :id => @repository.id }.should change{ Repository.count }.by(-1)
    response.should redirect_to(platform_repositories_path(@repository.platform))
  end

  it_should_behave_like 'user with change projects in repository rights'
  it_should_behave_like 'not destroy personal repository'
end

describe RepositoriesController do
  before(:each) do
    stub_rsync_methods

    @platform = FactoryGirl.create(:platform)
    @repository = FactoryGirl.create(:repository, :platform =>  @platform)
    @personal_repository = FactoryGirl.create(:personal_repository)
    @project = FactoryGirl.create(:project)
    @another_user = FactoryGirl.create(:user)
    @create_params = {:repository => {:name => 'pro', :description => 'pro2'}, :platform_id => @platform.id}
  end

  context 'for guest' do
    [:index, :create].each do |action|
      it "should not be able to perform #{ action } action" do
        get action
        response.should redirect_to(new_user_session_path)
      end
    end

    [:show, :new, :add_project, :remove_project, :destroy].each do |action|
      it "should not be able to perform #{ action } action" do
        get action, :id => @repository.id
        response.should redirect_to(new_user_session_path)
      end
    end
  end

  context 'for admin' do
    before(:each) do
      @admin = FactoryGirl.create(:admin)
      set_session_for(@admin)
    end

    it_should_behave_like 'platform admin user'
    
  end
  
  context 'for platform owner user' do
    before(:each) do
      @user = FactoryGirl.create(:user)
      set_session_for(@user)
      @repository.platform.update_attribute(:owner, @user)
      @repository.platform.relations.create!(:actor_type => 'User', :actor_id => @user.id, :role => 'admin')
    end

    it_should_behave_like 'platform admin user'
  end

  context 'for user' do
    before(:each) do
      @user = FactoryGirl.create(:user)
      set_session_for(@user)
    end
    
    it_should_behave_like 'registered user'

    it 'should not be able to perform new action' do
      get :new, :platform_id => @platform.id
      response.should redirect_to(forbidden_path)
    end

    it 'should not be able to perform create action' do
      post :create, @create_params
      lambda { post :create, @create_params }.should change{ Repository.count }.by(0)
      response.should redirect_to(forbidden_path)
    end
    
    it 'should not be able to destroy repository in main platform' do
      delete :destroy, :id => @repository.id
      response.should redirect_to(forbidden_path)
      lambda { delete :destroy, :id => @repository.id }.should_not change{ Repository.count }.by(-1)
    end

    it 'should not be able to add project to repository' do
      get :add_project, :id => @repository.id, :platform_id => @platform.id, :project_id => @project.id
      response.should redirect_to(forbidden_path)
      @repository.projects.should_not include (@project)
    end

    it 'should not be able to remove project from repository' do
      get :remove_project, :id => @repository.id, :platform_id => @platform.id, :project_id => @project.id
      response.should redirect_to(forbidden_path)
      @repository.projects.should_not include (@project)
    end

    it_should_behave_like 'not destroy personal repository'
  end

end
