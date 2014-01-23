require 'spec_helper'

describe Api::V1::UsersController do
  before(:all) { User.destroy_all }
  before do
    stub_symlink_methods
    @user = FactoryGirl.create(:user)
  end

  context 'for guest' do

    [:show_current_user, :notifiers].each do |action|
      it "should not be able to perform #{ action } action for a current user" do
        get action, format: :json
        response.should_not be_success
      end
    end

    it 'should be able to perform show action for a single user', :anonymous_access  => true do
      get :show, id: @user.id, format: :json
      response.should render_template(:show)
    end

    it 'should not be able to perform show action for a single user', :anonymous_access  => false do
      get :show, id: @user.id, format: :json
      response.should_not be_success
    end

    context 'should not be able to perform update action for a current user' do
      before do
        put :update, {user: {company: 'test_company'}}, format: :json
      end
      it { response.should_not be_success }
      it 'ensures that user has not been updated' do
        @user.reload
        @user.company.should_not == 'test_company'
      end
    end

    context 'should not be able to perform notifiers action for a current user' do
      before do
        put :notifiers, {notifiers: {can_notify: false}}, format: :json
      end
      it { response.should_not be_success }
      it 'ensures that user notification settings have not been updated' do
        @user.reload
        @user.notifier.can_notify.should be_true
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
        response.should be_success
      end
    end

    it 'should be able to perform show action for a single user' do
      get :show, id: @user.id, format: :json
      response.should render_template(:show)
    end

    context 'should be able to perform update action for a current user' do
      before do
        put :update, {user: {company: 'test_company'}}, format: :json
      end
      it { response.should be_success }
      it 'ensures that user has been updated' do
        @user.reload
        @user.company.should == 'test_company'
      end
    end

    context 'should be able to perform notifiers action for a current user' do
      before do
        put :notifiers, {notifiers: {can_notify: false}}, format: :json
      end
      it { response.should be_success }
      it 'ensures that user notification settings have been updated' do
        @user.reload
        @user.notifier.can_notify.should be_false
      end
    end

  end
end
