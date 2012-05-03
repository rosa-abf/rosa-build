# -*- encoding : utf-8 -*-
require 'spec_helper'

describe Users::ProfileController do
  before(:each) do
    stub_rsync_methods

    @simple_user = FactoryGirl.create(:user)
    @other_user = FactoryGirl.create(:user)
    @admin = FactoryGirl.create(:admin)
    %w[user1 user2 user3].each do |uname|
      FactoryGirl.create(:user, :uname => uname, :email => "#{ uname }@nonexistanceserver.com")
    end
    @update_params = {:email => 'new_email@test.com'}
  end

  context 'for guest' do
    it 'should not be able to view profile' do
      get :show, :owner_name => @simple_user.uname
      response.should redirect_to(new_user_session_path)
    end
  end

  context 'for simple user' do
    before(:each) do
      set_session_for(@simple_user)
    end

    it 'should be able to view profile' do
      get :show, :owner_name => @other_user.uname
      response.code.should eq('200')
    end

    context 'with mass assignment' do
      it 'should not be able to update role' do
        @simple_user.should_not allow_mass_assignment_of :role
      end

      it 'should not be able to update other user' do
        @simple_user.should_not allow_mass_assignment_of :id
      end
    end
  end
end
