require 'spec_helper'

describe FlashNotifiesController do
  before(:each) do
    stub_symlink_methods

    @user = FactoryGirl.create(:user)
    @create_params = {
      :flash_notify => {
        :body_ru => "Hello! I`m ru body",
        :body_en => "Hello! I`m en body",
        :status  => "error",
        :published => true
      }
    }

    @flash_notify  = FactoryGirl.create(:flash_notify)
    @flash_notify2 = FactoryGirl.create(:flash_notify)

    @update_params = {
      :id => @flash_notify,
      :flash_notify => {
        :body_ru => "updated!"
      }
    }
  end

  context 'for guest' do
    [:index, :create, :update, :edit, :new, :destroy].each do |action|
      it "should not be able to perform #{ action } action" do
        get action, :id => @flash_notify
        response.should redirect_to(new_user_session_path)
      end
    end

    it 'should not change objects count on create' do
      lambda { post :create, @create_params }.should change{ FlashNotify.count }.by(0)
    end

    it 'should not change objects count on destroy' do
      lambda { delete :destroy, :id => @flash_notify }.should change{ FlashNotify.count }.by(0)
    end

    it 'should not change flash notify body on update' do
      put :update, @update_params
      @flash_notify.reload.body_ru.should_not == "updated!"
    end
  end

  context 'for global admin' do
    before(:each) do
      @admin = FactoryGirl.create(:admin)
      @user = FactoryGirl.create(:user)
      set_session_for(@admin)
    end

    it 'should be able to perform index action' do
      get :index
      response.should render_template(:index)
    end

    it 'should load 2 flash notifies objects on index' do
      get :index
      assigns[:flash_notifies].count.should == 2
    end

    it 'should be able to perform new action' do
      get :new
      response.should render_template(:new)
    end

    it 'should be able to perform edit action' do
      get :edit
      response.should render_template(:edit)
    end

    it 'should be able to perform create action' do
      post :create, @create_params
      response.should redirect_to(flash_notifies_path)
    end

    it 'should change objects count on create' do
      lambda { post :create, @create_params }.should change{ FlashNotify.count }.by(1)
    end

    it 'should be able to perform destroy action' do
      delete :destroy, :id => @flash_notify
      response.should redirect_to(flash_notifies_path)
    end

    it 'should change objects count on destroy' do
      lambda { delete :destroy, :id => @flash_notify }.should change{ FlashNotify.count }.by(-1)
    end

    it 'should be able to perform update action' do
      put :update, @update_params
      response.should redirect_to(flash_notifies_path)
    end

    it 'should change flash notify body on update' do
      put :update, @update_params
      @flash_notify.reload.body_ru.should == "updated!"
    end
  end

  context 'for simple user' do
    before(:each) do
      @user = FactoryGirl.create(:user)
      set_session_for(@user)
    end

    [:index, :create, :update, :edit, :new, :destroy].each do |action|
      it "should not be able to perform #{ action } action" do
        get action, :id => @flash_notify
        response.should redirect_to(forbidden_path)
      end
    end

    it 'should not change objects count on create' do
      lambda { post :create, @create_params }.should change{ FlashNotify.count }.by(0)
    end

    it 'should not change objects count on destroy' do
      lambda { delete :destroy, :id => @flash_notify }.should change{ FlashNotify.count }.by(0)
    end

    it 'should not change flash notify body on update' do
      put :update, @update_params
      @flash_notify.reload.body_ru.should_not == "updated!"
    end
  end
end
