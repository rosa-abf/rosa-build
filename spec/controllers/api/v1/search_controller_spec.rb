require 'spec_helper'

shared_examples_for 'able search with api' do
  it 'should be able to search' do
    get :index, format: :json
    response.should be_success
    response.should render_template(:index)
  end
end
shared_examples_for 'not able search with api' do
  it 'should not be able to search' do
    get :index, format: :json
    response.code.should eq('401')
  end
end

describe Api::V1::SearchController, type: :controller do
  before { stub_symlink_methods }

  context 'as guest' do
    if APP_CONFIG['anonymous_access']
      it_should_behave_like 'able search with api'
    else
      it_should_behave_like 'not able search with api'
    end
  end

  context 'as user' do
    before {set_session_for FactoryGirl.create(:user)}

    it_should_behave_like 'able search with api'
  end
end
