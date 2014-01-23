require 'spec_helper'

def create_key_pair(repository, user)
  @key_pair = FactoryGirl.create(:key_pair, repository: repository, user: user)
end

shared_examples_for 'token of platform for owner' do
  [:index, :new].each do |action|
    it "should be able to perform #{action} action" do
      get action, platform_id: @platform
      response.should render_template(action)
    end
  end

  it 'should not be able to perform show action' do
    get :show, platform_id: @platform, id: @platform_token
    response.should render_template(:show)
  end

  it 'should be able to perform create action' do
    post :create, @create_params
    response.should redirect_to(platform_tokens_path(@platform))
  end

  it 'should create key pair into db on create action' do
    lambda { post :create, @create_params }.should change{Token.count}.by(1)
  end
end

shared_examples_for 'token of platform for simple user or guest' do
  [:index, :new].each do |action|
    it "should not be able to perform #{ action } action" do
      get action, platform_id: @platform
      response.should redirect_to(redirected_url)
    end
  end

  it 'should not be able to perform show action' do
    get :show, platform_id: @platform, id: @platform_token
    response.should redirect_to(redirected_url)
  end

  it 'should not be able to perform show action' do
    post :create, @create_params
    response.should redirect_to(redirected_url)
  end

  it 'should not change objects count on create success' do
    lambda { post :create, @create_params }.should change{ Token.count }.by(0)
  end
end

describe Platforms::TokensController do
  before do
    stub_symlink_methods

    @platform = FactoryGirl.create(:platform)
    @user = FactoryGirl.create(:user)
    @platform_token = FactoryGirl.create(:platform_token, subject: @platform)
    @create_params = {
      platform_id: @platform,
      tokens: {
        description: 'description'
      }
    }
  end

  it_should_behave_like 'token of platform for simple user or guest' do
    let(:redirected_url) { new_user_session_path }
  end

  context 'for global admin' do
    before(:each) do
      @admin = FactoryGirl.create(:admin)
      @user = FactoryGirl.create(:user)
      set_session_for(@admin)
    end

    it_should_behave_like 'token of platform for owner'
  end

  context 'for owner user' do
    before(:each) do
      @user = FactoryGirl.create(:user)
      set_session_for(@user)

      @platform.owner = @user
      @platform.save
    end

    it_should_behave_like 'token of platform for owner'
  end

  context 'for admin user' do
    before(:each) do
      @user = FactoryGirl.create(:user)
      set_session_for(@user)
      @platform.relations.create!(actor_type: 'User', actor_id: @user.id, role: 'admin')
    end

    it_should_behave_like 'token of platform for owner'
  end

  context 'for reader user' do
    before do
      @user = FactoryGirl.create(:user)
      set_session_for(@user)
      @platform.relations.create!(actor_type: 'User', actor_id: @user.id, role: 'reader')
    end

    it_should_behave_like 'token of platform for simple user or guest' do
      let(:redirected_url) { forbidden_url }
    end
  end

  context 'for simple user' do
    before do
      @user = FactoryGirl.create(:user)
      set_session_for(@user)
    end

    it_should_behave_like 'token of platform for simple user or guest' do
      let(:redirected_url) { forbidden_url }
    end
  end

end
