# -*- encoding : utf-8 -*-
require 'spec_helper'

shared_examples_for 'platform owner' do

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

shared_examples_for 'system registered user' do
  it 'should be able to perform index action' do
    get :index
    response.should render_template(:index)
  end

  it 'should be able to perform show action' do
    get :show, :id => @platform.id
    response.should render_template(:show)
    assigns(:platform).should eq @platform
  end

  it 'should be able to perform members action' do
    get :members, :id => @platform.id
    response.should render_template(:members)
    response.should be_success
  end

  it 'should be able to perform advisories action' do
    get :advisories, :id => @platform.id
    response.should render_template(:advisories)
    response.should be_success
  end

end
 
shared_examples_for 'user without create rights' do

  it 'should not be able to perform new action' do
    get :new
    response.should redirect_to(forbidden_path)
  end

  it 'should not be able to create platform' do
    post :create, @create_params
    response.should redirect_to(forbidden_path)
  end
end

describe Platforms::PlatformsController do
  before(:each) do
    stub_symlink_methods

    @platform = FactoryGirl.create(:platform)
    @personal_platform = FactoryGirl.create(:platform, :platform_type => 'personal')
    
    @user = FactoryGirl.create(:user)
    set_session_for(@user)

    @create_params = {:platform => {
      :name => 'pl1',
      :description => 'pl1',
      :platform_type => 'main',
      :distrib_type => APP_CONFIG['distr_types'].first
    }}
  end

  context 'for guest' do
    before(:each) do
      set_session_for(User.new)
    end

    [:index, :create].each do |action|
      it "should not be able to perform #{ action } action" do
        get action
        response.should redirect_to(new_user_session_path)
      end
    end

    [:new, :edit, :clone, :destroy].each do |action|
      it "should not be able to perform #{ action } action" do
        get action, :id => @platform
        response.should redirect_to(new_user_session_path)
      end
    end

    [:show, :members, :advisories].each do |action|
      it "should not be able to perform #{ action } action", :anonymous_access => false do
        get action, :id => @platform
        response.should redirect_to(new_user_session_path)
      end
    end

    [:show, :members, :advisories].each do |action|
      it "should be able to perform #{ action } action", :anonymous_access => true do
        get action, :id => @platform
        response.should render_template(action)
        response.should be_success
      end
    end

  end

  context 'for global admin' do
    before(:each) do
      @user.role = "admin"
      @user.save
    end

    it_should_behave_like 'system registered user'
    it_should_behave_like 'platform owner'

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

    it 'should create platform with mentioned owner if owner id present' do
      owner = FactoryGirl.create(:user)
      post :create, @create_params.merge({:admin_id => owner.id, :admin_uname => owner.uname})
      Platform.last.owner.id.should eql(owner.id)
    end
      
    it 'should create platform with current user as owner if owner id not present' do
      post :create, @create_params
      Platform.last.owner.id.should eql(@user.id)
    end

  end

  context 'for owner user' do
    before(:each) do
      @user = @platform.owner
      set_session_for(@user)
    end

    it_should_behave_like 'system registered user'
    it_should_behave_like 'user without create rights'
    it_should_behave_like 'platform owner'

  end

  context 'for reader user' do
    before(:each) do
      @platform.relations.create!(:actor_type => 'User', :actor_id => @user.id, :role => 'reader')
    end

    it_should_behave_like 'system registered user'
    it_should_behave_like 'user without create rights'

    it 'should not be able to perform destroy action' do
      delete :destroy, :id => @platform.id
      response.should redirect_to(forbidden_path)
    end
  end
end
