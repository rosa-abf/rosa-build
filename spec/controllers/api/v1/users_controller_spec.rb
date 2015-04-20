require 'spec_helper'

describe Api::V1::UsersController, type: :controller do
  before(:all) { User.destroy_all }
  before do
    stub_symlink_methods
    @user = FactoryGirl.create(:user)
  end

  context 'for guest' do

    [:show_current_user, :notifiers].each do |action|
      it "should not be able to perform #{ action } action for a current user" do
        get action, format: :json
        expect(response).to_not be_success
      end
    end

    it 'should be able to perform show action for a single user', :anonymous_access  => true do
      get :show, id: @user.id, format: :json
      expect(response).to render_template(:show)
    end

    it 'should not be able to perform show action for a single user', :anonymous_access  => false do
      get :show, id: @user.id, format: :json
      expect(response).to_not be_success
    end

    context 'should not be able to perform update action for a current user' do
      it 'ensures that user has not been updated' do
        put :update, user: { company: 'test_company' }, format: :json
        expect(response).to_not be_success
        expect(@user.reload.company).to_not eq 'test_company'
      end
    end

    context 'should not be able to perform notifiers action for a current user' do
      before do
      end
      it 'ensures that user notification settings have not been updated' do
        put :notifiers, notifiers: { can_notify: false }, format: :json
        expect(response).to_not be_success
        expect(@user.reload.notifier.can_notify).to be_truthy
      end
    end

  end

  context 'for simple user' do
    before do
      http_login(@user)
    end

    [:show_current_user, :notifiers].each do |action|
      it "should be able to perform #{ action } action for a current user" do
        get action, format: :json
        expect(response).to be_success
      end
    end

    it 'should be able to perform show action for a single user' do
      get :show, id: @user.id, format: :json
      expect(response).to render_template(:show)
    end

    context 'should be able to perform update action for a current user' do
      it 'ensures that user has been updated' do
        put :update, user: { company: 'test_company' }, format: :json
        expect(response).to be_success
        expect(@user.reload.company).to eq 'test_company'
      end
    end

    context 'should be able to perform notifiers action for a current user' do
      it 'ensures that user notification settings have been updated' do
        put :notifiers, notifiers: {can_notify: false }, format: :json
        expect(response).to be_success
        expect(@user.reload.notifier.can_notify).to be_falsy
      end
    end

  end
end
