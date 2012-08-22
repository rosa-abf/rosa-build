# -*- encoding : utf-8 -*-
require 'spec_helper'

shared_examples_for 'api platform user with reader rights' do
  include_examples "api platform user with show rights"

  it 'should be able to perform index action' do
    get :index, :format => :json
    response.should render_template(:index)
  end
end

shared_examples_for 'api platform user with reader rights for hidden platform' do
  before(:each) do
    @platform.update_column(:visibility, 'hidden')
  end

  it_should_behave_like 'api platform user with show rights'
end

shared_examples_for 'api platform user without reader rights for hidden platform' do
  before(:each) do
    @platform.update_column(:visibility, 'hidden')
  end

  it_should_behave_like 'api platform user without show rights'
end

shared_examples_for "api platform user with show rights" do
  it 'should be able to perform show action' do
    get :show, :id => @platform.id, :format => :json
    response.should render_template(:show)
  end
end

shared_examples_for "api platform user without show rights" do
  it 'should not be able to perform show action' do
    get :show, :id => @platform.id, :format => :json
    response.body.should == {"message" => "Access violation to this page!"}.to_json
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
      response.status.should == 401
    end

    it "should not be able to perform show action" do
      get :show, :id => @platform.id, :format => :json
      response.status.should == 401
    end
  end

  context 'for global admin' do
    before(:each) do
      @admin = FactoryGirl.create(:admin)
      @user = FactoryGirl.create(:user)
      set_session_for(@admin)
    end

    it_should_behave_like 'api platform user with reader rights'
    it_should_behave_like 'api platform user with reader rights for hidden platform'
  end

  context 'for owner user' do
    before(:each) do
      @user = FactoryGirl.create(:user)
      set_session_for(@user)
      @platform.owner = @user; @platform.save
      @platform.relations.create!(:actor_type => 'User', :actor_id => @user.id, :role => 'admin')
    end

    it_should_behave_like 'api platform user with reader rights'
    it_should_behave_like 'api platform user with reader rights for hidden platform'
  end

  context 'for reader user' do
    before(:each) do
      @user = FactoryGirl.create(:user)
      set_session_for(@user)
      @platform.relations.create!(:actor_type => 'User', :actor_id => @user.id, :role => 'reader')
    end

    it_should_behave_like 'api platform user with reader rights'
    it_should_behave_like 'api platform user with reader rights for hidden platform'
  end

  context 'for simple user' do
    before(:each) do
      @user = FactoryGirl.create(:user)
      set_session_for(@user)
    end

    it_should_behave_like 'api platform user with reader rights'
    it_should_behave_like 'api platform user without reader rights for hidden platform'
  end
end
