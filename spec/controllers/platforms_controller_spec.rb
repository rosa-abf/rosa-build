require 'spec_helper'

describe PlatformsController do
  before(:each) do
    @platform = Factory(:platform)
    @personal_platform = Factory(:platform, :platform_type => 'personal')
    @user = Factory(:user)
    @create_params = {:platform => {
      :name => 'pl1',
      :unixname => 'pl1',
      :platform_type => 'main',
      :distrib_type => APP_CONFIG['distr_types'].first
    }}
	end

  context 'for guest' do
    it "should not be able to perform easy_urpmi action" do
      get :easy_urpmi
      response.should redirect_to(forbidden_path)
    end

    [:index, :create].each do |action|
      it "should not be able to perform #{ action } action" do
        get action
        response.should redirect_to(new_user_session_path)
      end
    end

    [:show, :new, :edit, :freeze, :unfreeze, :clone, :destroy].each do |action|
      it "should not be able to perform #{ action } action" do
        get action, :id => @platform
        response.should redirect_to(new_user_session_path)
      end
    end
  end

  context 'for global admin' do
    before(:each) do
      @admin = Factory(:admin)
      set_session_for(@admin)
    end

    it 'should be able to perform index action' do
      get :index
      response.should render_template(:index)
    end

    it 'should be able to perform new action' do
      get :new
      response.should render_template(:new)
    end

    it 'should be able to perform create action' do
      post :create, @create_params
      response.should redirect_to(platform_path(Platform.last))
    end

    it 'should set flash notice on create success' do
      post :create, @create_params
      flash[:notice].should_not be_blank
    end

    it 'should be able to perform destroy action' do
      delete :destroy, :id => @platform.id
      response.should redirect_to(root_path)
    end

    it 'should not be able to destroy personal platform' do
      delete :destroy, :id => @personal_platform.id
      response.should redirect_to(forbidden_path)
    end
  end

  context 'for owner user' do
    before(:each) do
      @user = Factory(:user)
      set_session_for(@user)
      @platform.update_attribute(:owner, @user)
      r = @platform.relations.build(:object_type => 'User', :object_id => @user.id, :role => 'admin')
      r.save!
    end

    it 'should be able to perform index action' do
      get :index
      response.should render_template(:index)
    end

    it 'should be able to perform new action' do
      get :new
      response.should redirect_to(forbidden_path)
    end

    it 'should be able to perform create action' do
      post :create, @create_params
      response.should redirect_to(forbidden_path)
    end

    it 'should set flash notice on create success' do
      post :create, @create_params
      response.should redirect_to(forbidden_path)
    end

    it 'should be able to perform destroy action' do
      delete :destroy, :id => @platform.id
      response.should redirect_to(root_path)
    end

    it 'should not be able to destroy personal platform' do
      delete :destroy, :id => @personal_platform.id
      response.should redirect_to(forbidden_path)
    end
  end

  context 'for reader user' do
    before(:each) do
      @user = Factory(:user)
      set_session_for(@user)
      r = @platform.relations.build(:object_type => 'User', :object_id => @user.id, :role => 'reader')
      r.save!
    end

    it 'should be able to perform index action' do
      get :index
      response.should render_template(:index)
    end

    it 'should not be able to perform create action' do
      post :create, @create_params
      response.should redirect_to(forbidden_path)
    end

    it 'should set flash notice on create success' do
      post :create, @create_params
      response.should redirect_to(forbidden_path)
    end

    it 'should not be able to perform destroy action' do
      delete :destroy, :id => @platform.id
      response.should redirect_to(forbidden_path)
    end
  end
end
