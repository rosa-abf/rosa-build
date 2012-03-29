# -*- encoding : utf-8 -*-
require 'spec_helper'

shared_examples_for 'platform owner' do
  it_should_behave_like 'platform index viewer'

  it 'should not be able to destroy personal platform' do
    delete :destroy, :id => @personal_platform.id
    response.should redirect_to(forbidden_path)
  end

  it 'should change objects count on destroy success' do
    lambda { delete :destroy, :id => @platform.id }.should change{ Platform.count }.by(-1)
  end

  it 'should be able to perform destroy action' do
    delete :destroy, :id => @platform.id
    response.should redirect_to(platforms_path)
  end
end

shared_examples_for 'platform index viewer' do
  it 'should be able to perform index action' do
    get :index
    response.should render_template(:index)
  end
end

shared_examples_for 'user without create rights' do
  it 'should not be able to create platform' do
    post :create, @create_params
    response.should redirect_to(forbidden_path)
  end
end

describe PlatformsController do
  before(:each) do
    stub_rsync_methods

    @platform = Factory(:platform)
    @personal_platform = Factory(:platform, :platform_type => 'personal')
    @user = Factory(:user)
    @create_params = {:platform => {
      :name => 'pl1',
      :description => 'pl1',
      :platform_type => 'main',
      :distrib_type => APP_CONFIG['distr_types'].first
    }}
	end

  context 'for guest' do

    [:index, :create].each do |action|
      it "should not be able to perform #{ action } action" do
        get action
        response.should redirect_to(new_user_session_path)
      end
    end

    [:show, :new, :edit, :clone, :destroy].each do |action|
      it "should not be able to perform #{ action } action" do
        get action, :id => @platform
        response.should redirect_to(new_user_session_path)
      end
    end
  end

  context 'for global admin' do
    before(:each) do
      @admin = Factory(:admin)
      @user = Factory(:user)
      set_session_for(@admin)
    end

    it 'should be able to perform new action' do
      get :new
      response.should render_template(:new)
    end

    it 'should be able to perform create action' do
      post :create, @create_params
      response.should redirect_to(platform_path(Platform.last))
    end

    it 'should change objects count on create success' do
      lambda { post :create, @create_params }.should change{ Platform.count }.by(1)
    end

    it_should_behave_like 'platform owner'


    it 'should create platform with mentioned owner if owner id present' do
      post :create, @create_params.merge({:admin_id => @user.id, :admin_uname => @user.uname})
      Platform.last.owner.id.should eql(@user.id)
    end
      
    it 'should create platform with current user as owner if owner id not present' do
      post :create, @create_params
      Platform.last.owner.id.should eql(@admin.id)
    end

  end

  context 'for owner user' do
    before(:each) do
      @user = Factory(:user)
      set_session_for(@user)
      @platform.update_attribute(:owner, @user)
      @platform.relations.create!(:object_type => 'User', :object_id => @user.id, :role => 'admin')
    end

    it_should_behave_like 'user without create rights'
    it_should_behave_like 'platform owner'

    it 'should be able to perform new action' do
      get :new
      response.should redirect_to(forbidden_path)
    end

    it 'should be able to perform create action' do
      post :create, @create_params
      response.should redirect_to(forbidden_path)
    end

  end

  context 'for reader user' do
    before(:each) do
      @user = Factory(:user)
      set_session_for(@user)
      @platform.relations.create!(:object_type => 'User', :object_id => @user.id, :role => 'reader')
    end

    it_should_behave_like 'platform index viewer'
    it_should_behave_like 'user without create rights'

    it 'should not be able to perform destroy action' do
      delete :destroy, :id => @platform.id
      response.should redirect_to(forbidden_path)
    end
  end
end
