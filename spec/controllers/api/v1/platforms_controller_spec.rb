# -*- encoding : utf-8 -*-
require 'spec_helper'

shared_examples_for 'api platform viewer' do
  it 'should be able to perform index action' do
    get :index, :format => :json
    response.should render_template(:index)
  end

  it 'should be able to perform show action' do
    get :show, :id => @platform.id, :format => :json
    response.should render_template(:show)
  end
end

describe Api::V1::PlatformsController do
  before(:each) do
    stub_symlink_methods

    @platform = FactoryGirl.create(:platform)
    @personal_platform = FactoryGirl.create(:platform, :platform_type => 'personal')
    @user = FactoryGirl.create(:user)
  end

  context 'for guest' do
    it "should not be able to perform index action" do
      get :index, :format => :json
      response.should redirect_to(new_user_session_path)
    end

    it "should not be able to perform show action" do
      get :show, :id => @platform.id, :format => :json
      response.should redirect_to(new_user_session_path)
    end
  end

  context 'for global admin' do
    before(:each) do
      @admin = FactoryGirl.create(:admin)
      @user = FactoryGirl.create(:user)
      set_session_for(@admin)
    end

    it_should_behave_like 'api platform viewer'
  end

  context 'for owner user' do
    before(:each) do
      @user = FactoryGirl.create(:user)
      set_session_for(@user)
      @platform.owner = @user; @platform.save
      @platform.relations.create!(:actor_type => 'User', :actor_id => @user.id, :role => 'admin')
    end

    it_should_behave_like 'api platform viewer'
  end

  context 'for reader user' do
    before(:each) do
      @user = FactoryGirl.create(:user)
      set_session_for(@user)
      @platform.relations.create!(:actor_type => 'User', :actor_id => @user.id, :role => 'reader')
    end

    it_should_behave_like 'api platform viewer'
  end
end
