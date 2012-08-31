# -*- encoding : utf-8 -*-
require 'spec_helper'

shared_examples_for 'guest user' do

  # Only one action for now here
  guest_actions = [:index]

  if APP_CONFIG['anonymous_access']
    guest_actions.each do |action|
      it "should be able to perform #{ action } action" do
        get action, :platform_id => @platform.id
        response.should be_success
      end
    end
  else  # non-anonymous access
    guest_actions.each do |action|
      it "should not be able to perform #{ action } action" do
        get action, :platform_id => @platform.id
        response.should redirect_to(new_user_session_path)
      end
    end
  end
end

describe Platforms::MaintainersController do
  before(:each) do
    stub_symlink_methods

    @platform = FactoryGirl.create(:platform)
    @platform.visibility = 'open'

    # JS format is the primary target for this callback
    @assignee_rq = { :platform_id => @platform.id, :package => 'test', :format => 'js' }
  end

  context 'for guest' do
    it_should_behave_like 'guest user'
  end
end


