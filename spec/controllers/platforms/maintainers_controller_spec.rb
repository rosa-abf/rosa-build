# -*- encoding : utf-8 -*-
require 'spec_helper'

shared_examples_for 'guest user' do
  before(:each) do
    if APP_CONFIG['anonymous_access']
    else
      @user = FactoryGirl.create(:user)
      set_session_for(@user)
    end
  end

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
	end

	context 'for guest' do
    it_should_behave_like 'guest user'
  end

end


