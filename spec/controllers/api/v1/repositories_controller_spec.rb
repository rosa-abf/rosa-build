# -*- encoding : utf-8 -*-
require 'spec_helper'

shared_examples_for 'api repository user with reader rights' do
  it_should_behave_like 'api repository user with show rights'
end

shared_examples_for 'api repository user with reader rights for hidden platform' do
  before(:each) do
    @platform.update_column(:visibility, 'hidden')
  end

  it_should_behave_like 'api repository user with show rights'
end

shared_examples_for 'api repository user without reader rights for hidden platform' do
  before(:each) do
    @platform.update_column(:visibility, 'hidden')
  end

  it_should_behave_like 'api repository user without show rights'
end

shared_examples_for "api repository user with show rights" do
  it 'should be able to perform show action' do
    get :show, :id => @repository.id, :format => :json
    response.should render_template(:show)
  end
end

shared_examples_for "api repository user without show rights" do
  it 'should not be able to perform show action' do
    get :show, :id => @repository.id, :format => :json
    response.body.should == {"message" => "Access violation to this page!"}.to_json
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
    it "should not be able to perform show action" do
      get :show, :id => @repository.id, :format => :json
      response.status.should == 401
    end
  end

  context 'for admin' do
    before(:each) do
      @admin = FactoryGirl.create(:admin)
      http_login(@admin)
    end

    it_should_behave_like 'api repository user with reader rights'
    it_should_behave_like 'api repository user with reader rights for hidden platform'
  end

  context 'for platform owner user' do
    before(:each) do
      @user = FactoryGirl.create(:user)
      http_login(@user)
      platform = @repository.platform
      platform.owner = @user; platform.save
      @repository.platform.relations.create!(:actor_type => 'User', :actor_id => @user.id, :role => 'admin')
    end

    it_should_behave_like 'api repository user with reader rights'
    it_should_behave_like 'api repository user with reader rights for hidden platform'
  end

  context 'for user' do
    before(:each) do
      @user = FactoryGirl.create(:user)
      http_login(@user)
    end

    it_should_behave_like 'api repository user with reader rights'
    it_should_behave_like 'api repository user without reader rights for hidden platform'
    it_should_behave_like 'api repository user with show rights'
  end
end
