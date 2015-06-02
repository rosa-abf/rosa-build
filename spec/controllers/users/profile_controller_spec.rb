require 'spec_helper'

describe Users::ProfileController, type: :controller do
  before(:each) do
    stub_symlink_methods

    @simple_user = FactoryGirl.create(:user)
    @other_user = FactoryGirl.create(:user)
    @admin = FactoryGirl.create(:admin)
    %w[user1 user2 user3].each do |uname|
      FactoryGirl.create(:user, uname: uname, email: "#{ uname }@nonexistanceserver.com")
    end
    @update_params = {email: 'new_email@test.com'}
  end

  context 'for guest' do
    it 'should be able to view profile', anonymous_access: true do
      get :show, uname: @simple_user.uname
      expect(response).to be_success
    end
    it 'should not be able to perform show action', anonymous_access: false do
      get :show, uname: @simple_user.uname
      expect(response).to redirect_to(new_user_session_path)
    end
  end

  context 'for simple user' do
    before(:each) do
      set_session_for(@simple_user)
    end

    it 'should be able to view profile' do
      get :show, uname: @other_user.uname
      expect(response).to be_success
    end

  end
end
