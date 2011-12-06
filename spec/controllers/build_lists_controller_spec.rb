require 'spec_helper'

describe BuildListsController do
  context 'crud' do
    # let(:build_list) { Factory(:build_list) }

    context 'for guest' do
      it 'should not be able to perform all action' do
        get :all
        response.should redirect_to(new_user_session_path)
      end
    end

    context 'for user' do
      before(:each) { set_session_for Factory(:user) }
  
      it 'should not be able to perform all action' do
        get :all
        response.should redirect_to(forbidden_url)
      end
    end

    context 'for admin' do
      before(:each) { set_session_for Factory(:admin) }

      it "should be able to perform all action without exception" do
        get :all
        assigns[:build_server_status].should == {} # TODO stub to isolate
        response.should be_success
      end
    end
  end

  context 'callbacks' do
  end
end
