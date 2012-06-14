# -*- encoding : utf-8 -*-
require 'spec_helper'

shared_examples_for 'guest user' do
  before(:each) do
    unless APP_CONFIG['anonymous_access']
      @user = FactoryGirl.create(:user)
      set_session_for(@user)
    end
  end

  # Only one action for now here
  [:index].each do |action|
    it "should be able to perform #{ action } action" do
      get action, :platform_id => @platform.id
      response.should be_success
    end
  end
end

describe Platforms::MaintainersController do
  before(:each) do
    stub_symlink_methods

    @platform = FactoryGirl.create(:platform)
    @platform.visibility = 'open'

    @assignee_rq = { :platform_id => @platform.id, :package => 'test' }
  end

  context 'for guest' do
    it_should_behave_like 'guest user'

    it 'should not be able to get api' do
      get :assignee, @assignee_rq
      response.response_code.should equal(403)
    end
  end

  context 'for bugzilla' do
    before(:each) do
      request.remote_addr = APP_CONFIG['external_tracker_ip']
    end

    it_should_behave_like 'guest user'

    it 'should be able to get api' do
      get :assignee, @assignee_rq
      response.response_code.should equal(200)
    end
  end
end


