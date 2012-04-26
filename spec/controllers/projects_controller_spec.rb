# -*- encoding : utf-8 -*-
require 'spec_helper'

describe ProjectsController do

  before(:each) do
    stub_rsync_methods

    @project = FactoryGirl.create(:project)
    @another_user = FactoryGirl.create(:user)
    @create_params = {:project => {:name => 'pro'}}
    @update_params = {:project => {:name => 'pro2'}}
  end

  context 'for guest' do
    it 'should not be able to perform index action' do
      get :index
      response.should redirect_to(new_user_session_path)
    end

    it 'should not be able to perform update action' do
      put :update, {:id => @project.id}.merge(@update_params)
      response.should redirect_to(new_user_session_path)
    end
  end

  context 'for admin' do
    before(:each) do
      @admin = FactoryGirl.create(:admin)
      set_session_for(@admin)
    end

    it_should_behave_like 'projects user with admin rights'
    it_should_behave_like 'projects user with reader rights'

    it 'should be able to perform create action' do
      post :create, @create_params
      response.should redirect_to(project_path( Project.last.id ))
    end

    it 'should change objects count on create' do
      lambda { post :create, @create_params }.should change{ Project.count }.by(1)
    end
  end

  context 'for owner user' do
    before(:each) do
      @user = FactoryGirl.create(:user)
      set_session_for(@user)
      @project.update_attribute(:owner, @user)
      @project.relations.create!(:actor_type => 'User', :actor_id => @user.id, :role => 'admin')
    end

    it_should_behave_like 'projects user with admin rights'
    it_should_behave_like 'user with rights to view projects'

    it 'should be able to perform destroy action' do
      delete :destroy, {:id => @project.id}
      response.should redirect_to(@project.owner)
    end

    it 'should change objects count on destroy' do
      lambda { delete :destroy, :id => @project.id }.should change{ Project.count }.by(-1)
    end

    it 'should not be able to fork project' do
      post :fork, :id => @project.id
      response.should redirect_to(forbidden_path)
    end

  end

  context 'for reader user' do
    before(:each) do
      @user = FactoryGirl.create(:user)
      set_session_for(@user)
      @project.relations.create!(:actor_type => 'User', :actor_id => @user.id, :role => 'reader')
    end

    it_should_behave_like 'projects user with reader rights'
  end

  context 'for writer user' do
    before(:each) do
      @user = FactoryGirl.create(:user)
      set_session_for(@user)
      @project.relations.create!(:actor_type => 'User', :actor_id => @user.id, :role => 'writer')
    end

    it_should_behave_like 'projects user with reader rights'

    it 'should not be able to create project to other group' do
      group = FactoryGirl.create(:group)
      post :create, @create_params.merge({:who_owns => 'group', :owner_id => group.id})
      response.should redirect_to(forbidden_path)
    end

    it 'should not be able to fork project to other group' do
      group = FactoryGirl.create(:group)
      post :fork, :id => @project.id, :group => group.id
      response.should redirect_to(forbidden_path)
    end

    it 'should be able to fork project to group' do
      group = FactoryGirl.create(:group)
      group.actors.create(:actor_type => 'User', :actor_id => @user.id, :role => 'admin')
      post :fork, :id => @project.id, :group => group.id
      response.should redirect_to(project_path(group.projects.first.id))
    end
  end

  context 'search projects' do
    before(:each) do
      @admin = FactoryGirl.create(:admin)
      @project1 = FactoryGirl.create(:project, :name => 'perl-debug')
      @project2 = FactoryGirl.create(:project, :name => 'perl')
      set_session_for(@admin)
    end

    pending 'should return projects in right order' do
      get :index, :query => 'per'
      assigns(:projects).should eq([@project2, @project1])
    end
  end

  context 'for other user' do
    it 'should not be able to fork hidden project' do
      @user = FactoryGirl.create(:user)
      set_session_for(@user)
      @project.update_attribute(:visibility, 'hidden')
      post :fork, :id => @project.id
      response.should redirect_to(forbidden_path)
    end
  end
end
