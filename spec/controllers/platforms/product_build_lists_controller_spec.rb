# -*- encoding : utf-8 -*-
require 'spec_helper'

shared_examples_for 'admin' do

  it "should be able to create ProductBuildList" do
    expect {
      post :create, valid_attributes
    }.to change(ProductBuildList, :count).by(1)
    response.should redirect_to([@product.platform, @product])
  end

  it "should be able to destroy ProductBuildList" do
    expect {
      delete :destroy, valid_attributes_for_destroy
    }.to change(ProductBuildList, :count).by(-1)
    response.should redirect_to([@pbl.product.platform, @pbl.product])
  end

  it 'should be able to view ProductBuildLists' do
    get :index
    response.should render_template(:index)
  end

end

describe Platforms::ProductBuildListsController do
  before(:each) do
    stub_rsync_methods
  end

  context 'crud' do

    before(:each) do
       @product = FactoryGirl.create(:product)
       @pbl = FactoryGirl.create(:product_build_list, :product => @product)
    end

    def valid_attributes
      {:product_id => @product.id, :platform_id => @product.platform_id}
    end

    def valid_attributes_for_destroy
      {:id => @pbl.id, :product_id => @pbl.product.id, :platform_id => @pbl.product.platform.id }
    end
    
    context 'for guest' do
      it 'should not be able to create ProductBuildList' do
        post :create, valid_attributes
        response.should redirect_to(new_user_session_path)
      end

      it 'should not be able to destroy ProductBuildList' do
        delete :destroy, valid_attributes_for_destroy
        response.should redirect_to(new_user_session_path)
      end

      if APP_CONFIG['anonymous_access']
        it 'should be able to view ProductBuildLists' do
          get :index
          response.should be_success
        end
      else
        it 'should not be able to view ProductBuildLists' do
          get :index
          response.should redirect_to(new_user_session_path)
        end
      end
    end

    context 'for user' do
      before(:each) { set_session_for FactoryGirl.create(:user) }
  
      it 'should not be able to perform create action' do
        post :create, valid_attributes
        response.should redirect_to(forbidden_url)
      end

      it 'should not be able to perform create action' do
        delete :destroy, valid_attributes_for_destroy
        response.should redirect_to(forbidden_url)
      end

      it 'should be able to view ProductBuildLists' do
        get :index
        response.should render_template(:index)
      end 

    end

    context 'for platform admin' do
      before(:each) do
        @user = FactoryGirl.create(:user)
        set_session_for(@user)
        @pbl.product.platform.relations.create!(:actor_type => 'User', :actor_id => @user.id, :role => 'admin')
      end

      it_should_behave_like 'admin'

    end

    context 'for global admin' do
      before(:each)  {  set_session_for FactoryGirl.create(:admin) }

      it_should_behave_like 'admin'
      
    end
  end

  context 'callbacks' do

    let(:pbl) { FactoryGirl.create(:product_build_list) }
  
    before(:each) do
      mock(controller).authenticate_product_builder! {true}
    end

    def do_get
      get :status_build, :id => pbl.id, :status => ProductBuildList::BUILD_FAILED
      pbl.reload
    end

    it "should update ProductBuildList status" do
      expect { do_get }.to change(pbl, :status).to(ProductBuildList::BUILD_FAILED)
      response.should be_success
      response.body.should be_blank
    end
  end
end
