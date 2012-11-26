require 'spec_helper'

describe Api::V1::MaintainersController do
  let(:package) { FactoryGirl.create(:build_list_package) }

  context 'for guest' do
    it "should be able to perform index action", :anonymous_access  => true do
      get :index, :platform_id => package.platform_id, :format => :json
      should render_template(:index)
    end

    it 'should be able to perform get_id action', :anonymous_access  => false do
      get :index, :platform_id => package.platform_id, :format => :json
      response.status.should == 401
    end
  end

  context 'for simple user' do
    before do
      stub_symlink_methods
      http_login(FactoryGirl.create(:user))
    end

    it "should be able to perform index action" do
      get :index, :platform_id => package.platform_id, :format => :json
      should render_template(:index)
    end
  end
end
