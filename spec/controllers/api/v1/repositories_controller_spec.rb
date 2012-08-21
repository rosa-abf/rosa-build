# -*- encoding : utf-8 -*-
require 'spec_helper'

shared_examples_for 'api repositories view rights' do
  it 'should be able to perform index action' do
    get :index, :platform_id => @platform.id, :format => :json
    response.should render_template(:index)
  end

  it 'should be able to perform show action' do
    get :show, :id => @repository.id, :format => :json
    response.should render_template(:show)
  end
end

describe Api::V1::RepositoriesController do
  before(:each) do
    stub_symlink_methods

    @platform = FactoryGirl.create(:platform)
    @repository = FactoryGirl.create(:repository, :platform =>  @platform)
    @personal_repository = FactoryGirl.create(:personal_repository)
    @project = FactoryGirl.create(:project)
    @another_user = FactoryGirl.create(:user)
  end

  context 'for guest' do
    it "should not be able to perform index action" do
      get :index, :platform_id => @platform, :format => :json
      response.should redirect_to(new_user_session_path)
    end

    it "should not be able to perform show action" do
      get :show, :id => @repository.id, :format => :json
      response.should redirect_to(new_user_session_path)
    end
  end

  context 'for admin' do
    before(:each) do
      @admin = FactoryGirl.create(:admin)
      set_session_for(@admin)
    end

    it_should_behave_like 'api repositories view rights'
  end

  context 'for platform owner user' do
    before(:each) do
      @user = FactoryGirl.create(:user)
      set_session_for(@user)
      platform = @repository.platform
      platform.owner = @user; platform.save
      @repository.platform.relations.create!(:actor_type => 'User', :actor_id => @user.id, :role => 'admin')
    end

    it_should_behave_like 'api repositories view rights'
  end

  context 'for user' do
    before(:each) do
      @user = FactoryGirl.create(:user)
      set_session_for(@user)
    end

    it_should_behave_like 'api repositories view rights'
  end
end
