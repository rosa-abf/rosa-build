require 'spec_helper'

shared_examples_for 'user with users list viewer rights' do
  it 'should be able to perform index action' do
    get :index
    response.should render_template(:index)
  end

  it 'should assigns 5 users without filter params' do
    get :index
    assigns[:users].count.should == 5
  end

  it 'should find one user' do
    get :index, :filter => {:email => "user1@nonexistanceserver.com"}
    assigns[:users].size == 1
  end

  it 'should find user with searchable email' do
    get :index, :filter => {:email => "user1@nonexistanceserver.com"}
    assigns[:users].first.email.should == "user1@nonexistanceserver.com"
  end
end

describe UsersController do
  before(:each) do
    stub_rsync_methods

    @simple_user = Factory(:user)
    @admin = Factory(:admin)
    %w[user1 user2 user3].each do |uname|
      Factory(:user, :uname => uname, :email => "#{ uname }@nonexistanceserver.com")
    end
	end

  context 'for global admin' do
    before(:each) do
      set_session_for(@admin)
    end

    it_should_behave_like 'user with users list viewer rights'
  end

  context 'for guest' do
    it 'should not be able to perform index action' do
      get :index
      response.should redirect_to(new_user_session_path)
    end
  end

  context 'for simple user' do
    before(:each) do
      set_session_for(@simple_user)
    end

    it_should_behave_like 'user with users list viewer rights'
  end
end
