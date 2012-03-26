# -*- encoding : utf-8 -*-
require 'spec_helper'

describe ProductBuildListsController do
  before(:each) do
    stub_rsync_methods
  end

  context 'crud' do
    def valid_attributes
      {:product_id => product.id, :platform_id => product.platform_id}
    end

    let(:product) { Factory(:product) }

    context 'for guest' do
      it 'should not be able to perform create action' do
        post :create, valid_attributes
        response.should redirect_to(new_user_session_path)
      end
    end

    context 'for user' do
      before(:each) { set_session_for Factory(:user) }
  
      it 'should not be able to perform create action' do
        post :create, valid_attributes
        response.should redirect_to(forbidden_url)
      end
    end

    context 'for admin' do
      before(:each) { set_session_for Factory(:admin) }

      it "creates a new ProductBuildList" do
        expect {
          post :create, valid_attributes
        }.to change(ProductBuildList, :count).by(1)
      end

      it "redirects to the product" do
        post :create, valid_attributes
        response.should redirect_to([product.platform, product])
      end
    end
  end

  context 'callbacks' do
    let(:product_build_list) { Factory(:product_build_list) }

    def do_get
      get :status_build, :id => product_build_list.id, :status => ProductBuildList::BUILD_FAILED
      product_build_list.reload
    end

    it do
      expect { do_get }.to change(product_build_list, :status).to(ProductBuildList::BUILD_FAILED)
    end

    it do
      do_get
      response.should be_success
      response.body.should be_blank
    end
  end
end
