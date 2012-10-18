# -*- encoding : utf-8 -*-
require 'spec_helper'

shared_examples_for 'api advisories user with show rights' do
  it 'should be able to perform show action' do
    get :show, :id => @advisory.advisory_id, :format => :json
    response.should be_success
  end

  it 'should be able to perform index action' do
    get :index, :format => :json
    response.should be_success
  end
end

describe Api::V1::AdvisoriesController do

  before do
    stub_symlink_methods

    @advisory = FactoryGirl.create(:advisory)
    @build_list = FactoryGirl.create(:build_list_core)
    @another_user = FactoryGirl.create(:user)
  end

  context 'for guest' do
    
    if APP_CONFIG['anonymous_access']
      it_should_behave_like 'api advisories user with show rights'
    end

    it 'should not be able to perform show action', :anonymous_access  => false do
      get :show, :id => @advisory.advisory_id, :format => :json
      response.should_not be_success
    end

    it 'should not be able to perform index action', :anonymous_access  => false do
      get :index, :format => :json
      response.should_not be_success
    end

  end

  context 'for simple user' do
    before do
      @user = FactoryGirl.create(:user)
      http_login(@user)
    end
    it_should_behave_like 'api advisories user with show rights'

  end

  context 'for admin' do
    before do
      @admin = FactoryGirl.create(:admin)
      http_login(@admin)
    end

    it_should_behave_like 'api advisories user with show rights'
  end

  context 'for user who has access to update build_list' do
    before do
      @user = FactoryGirl.create(:user)
      @build_list.project.relations.create(:role => 'фвьшт', :actor => @user)
      http_login(@user)
    end

    it_should_behave_like 'api advisories user with show rights'
  end

end
