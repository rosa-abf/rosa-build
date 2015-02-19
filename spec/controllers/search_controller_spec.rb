require 'spec_helper'

shared_examples_for 'able search' do
  it 'should be able to search' do
    get :index
    response.should be_success
    response.should render_template(:index)
  end
end
shared_examples_for 'not able search' do
  it 'should not be able to search' do
    get :index
    response.should redirect_to(controller.current_user ? forbidden_path : new_user_session_path)
  end
end

describe SearchController, type: :controller do
  before { stub_symlink_methods }

  context 'as guest' do
    if APP_CONFIG['anonymous_access']
      it_should_behave_like 'able search'
    else
      it_should_behave_like 'not able search'
    end
  end

  context 'as user' do
    before {set_session_for FactoryGirl.create(:user)}

    it_should_behave_like 'able search'
  end
end
