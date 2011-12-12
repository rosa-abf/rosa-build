require 'spec_helper'
#require "shared_examples/platforms_controller"

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

    it_should_behave_like 'able_to_perform_index#platforms'

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

    it_should_behave_like 'be_able_to_perform_destroy#platforms'
    it_should_behave_like 'change_objects_count_on_destroy_success'
    it_should_behave_like 'not_be_able_to_destroy_personal_platform'
  end

  context 'for owner user' do
    before(:each) do
      @user = Factory(:user)
      set_session_for(@user)
      @platform.update_attribute(:owner, @user)
      @platform.relations.create!(:object_type => 'User', :object_id => @user.id, :role => 'admin')
    end

    it_should_behave_like 'able_to_perform_index#platforms'
    it_should_behave_like 'not_be_able_to_perform_create#platforms'
    it_should_behave_like 'be_able_to_perform_destroy#platforms'
    it_should_behave_like 'change_objects_count_on_destroy_success'
    it_should_behave_like 'not_be_able_to_destroy_personal_platform'

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

    it_should_behave_like 'able_to_perform_index#platforms'
    it_should_behave_like 'not_be_able_to_perform_create#platforms'

    it 'should not be able to perform destroy action' do
      delete :destroy, :id => @platform.id
      response.should redirect_to(forbidden_path)
    end
  end
end
