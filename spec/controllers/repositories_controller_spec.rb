# -*- encoding : utf-8 -*-
require 'spec_helper'

describe RepositoriesController do
	before(:each) do
    stub_rsync_methods

    @repository = FactoryGirl.create(:repository)
    @personal_repository = FactoryGirl.create(:personal_repository)
    @platform = FactoryGirl.create(:platform)
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

    it 'should be able to perform new action' do
      get :new, :platform_id => @platform.id
      response.should render_template(:new)
    end

    it 'should be able to perform create action' do
      post :create, @create_params
      response.should redirect_to(platform_repositories_path(@platform.id))
    end

    it 'should change objects count after create action' do
      lambda { post :create, @create_params }.should change{ Repository.count }.by(1)
    end

    it_should_behave_like 'repository user with admin rights'
  end

  context 'for anyone except admin' do
  	before(:each) do
  		@user = FactoryGirl.create(:user)
  		set_session_for(@user)
		end

    it 'should not be able to perform new action' do
      get :new, :platform_id => @platform.id
      response.should redirect_to(forbidden_path)
    end

    it 'should not be able to perform create action' do
      post :create, @create_params
      response.should redirect_to(forbidden_path)
    end

    it 'should not change objects count after create action' do
      lambda { post :create, @create_params }.should change{ Repository.count }.by(0)
    end

    it_should_behave_like 'not destroy personal repository'
  end

  context 'for owner user' do
  	before(:each) do
  		@user = FactoryGirl.create(:user)
  		set_session_for(@user)
  		@repository.platform.update_attribute(:owner, @user)
  		@repository.platform.relations.create!(:object_type => 'User', :object_id => @user.id, :role => 'admin')
		end

    it_should_behave_like 'repository user with owner rights'
  end

  context 'for reader user' do
  	before(:each) do
  		@user = FactoryGirl.create(:user)
  		set_session_for(@user)
  		@repository.platform.relations.create!(:object_type => 'User', :object_id => @user.id, :role => 'reader')
		end

    it_should_behave_like 'repository user with reader rights'

    it 'should not be able to perform add_project action' do
      get :add_project, :id => @repository.id
      response.should redirect_to(forbidden_path)
    end

    it 'should not be able to perform add_project action with project_id param' do
      get :add_project, :id => @repository.id, :project_id => @project.id
      response.should redirect_to(forbidden_path)
    end

    it 'should not be able to perform destroy action' do
      delete :destroy, :id => @repository.id
      response.should redirect_to(forbidden_path)
    end
  end
end
