# -*- encoding : utf-8 -*-
require 'spec_helper'

describe AutocompletesController do
  before {stub_symlink_methods}

  context 'for user' do
    before do
      set_session_for(FactoryGirl.create(:user))
    end

    it 'should be able to perform autocomplete_group_uname action' do
      get :autocomplete_group_uname
      response.should be_success
    end

    it 'should be able to perform autocomplete_user_uname action' do
      get :autocomplete_user_uname
      response.should be_success
    end

  end

  context 'for guest' do

    before do
      set_session_for(User.new)
    end

    it 'should not be able to perform autocomplete_group_uname action' do
      get :autocomplete_group_uname
      response.should redirect_to(new_user_session_path)
    end

    it 'should not be able to perform autocomplete_user_uname action' do
      get :autocomplete_user_uname
      response.should redirect_to(new_user_session_path)
    end

  end
end
