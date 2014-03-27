require 'spec_helper'

def create_key_pair(repository, user)
  @key_pair = FactoryGirl.create(:key_pair, repository: repository, user: user)
end

shared_examples_for 'key_pair platform owner' do
  it 'should be able to perform index action' do
    get :index, platform_id: @platform
    response.should render_template(:index)
  end

  it 'should be able to perform create action' do
    post :create, @create_params
    response.should redirect_to(platform_key_pairs_path(@platform))
  end

  it 'should create key pair into db on create action' do
    lambda { post :create, @create_params }.should change{KeyPair.count}.by(1)
  end

  context "on destroy" do
    before(:each) do
      create_key_pair @repository, @user
    end

    it 'should be able to perform action' do
      delete :destroy, platform_id: @platform, id: @key_pair
      response.should redirect_to(platform_key_pairs_path(@platform))
    end

    it 'should delete key pair into db' do
      lambda { delete :destroy, platform_id: @platform, id: @key_pair }.should change{KeyPair.count}.by(-1)
    end
  end
end

shared_examples_for 'key_pair platform reader' do
  it 'should be able to perform index action' do
    get :index, platform_id: @platform
    response.should render_template(:index)
  end

  it 'should not be able to perform create action' do
    post :create, @create_params
    response.should redirect_to(forbidden_path)
  end

  it 'should not change objects count on create success' do
    lambda { post :create, @create_params }.should change{ KeyPair.count }.by(0)
  end

  context "on destroy" do
    before(:each) do
      create_key_pair @repository, @user
    end

    it 'should not be able to perform action' do
      delete :destroy, platform_id: @platform, id: @key_pair
      response.should redirect_to(forbidden_path)
    end

    it 'should not change objects count on destroy success' do
      lambda { delete :destroy, platform_id: @platform, id: @key_pair }.should change{KeyPair.count}.by(0)
    end
  end
end

describe Platforms::KeyPairsController do
  before(:each) do
    stub_symlink_methods

    @platform = FactoryGirl.create(:platform)
    @repository = FactoryGirl.create(:repository, platform: @platform)
    @user = FactoryGirl.create(:user)
    kp = FactoryGirl.build(:key_pair)
    @create_params = {
      platform_id: @platform,
      key_pair: {
        repository_id: @repository.id,
        public: kp.public,
        secret: kp.secret
      }
    }
  end

  context 'for guest' do
    [:index, :create].each do |action|
      it "should not be able to perform #{ action } action" do
        get action, platform_id: @platform
        response.should redirect_to(new_user_session_path)
      end
    end

    it 'should not change objects count on create success' do
      lambda { post :create, @create_params }.should change{ KeyPair.count }.by(0)
    end

    context 'on destroy' do
      before(:each) do
        create_key_pair @repository, @user
      end

      it 'should not change objects count on destroy success' do
        lambda { delete :destroy, platform_id: @platform, id: @key_pair }.should change{KeyPair.count}.by(0)
      end

      it "should not be able to perform destroy action" do
        delete :destroy, platform_id: @platform, id: @key_pair
        response.should redirect_to(new_user_session_path)
      end
    end
  end

  context 'for global admin' do
    before(:each) do
      @admin = FactoryGirl.create(:admin)
      @user = FactoryGirl.create(:user)
      set_session_for(@admin)
    end

    it_should_behave_like 'key_pair platform owner'
  end

  context 'for owner user' do
    before(:each) do
      @user = FactoryGirl.create(:user)
      set_session_for(@user)

      @platform.owner = @user
      @platform.save
    end

    it_should_behave_like 'key_pair platform owner'
  end

  context 'for admin user' do
    before(:each) do
      @user = FactoryGirl.create(:user)
      set_session_for(@user)
      create_relation(@platform, @user, 'admin')
    end

    it_should_behave_like 'key_pair platform owner'
  end

  context 'for reader user' do
    before(:each) do
      @user = FactoryGirl.create(:user)
      set_session_for(@user)
      create_relation(@platform, @user, 'reader')
    end

    it_should_behave_like 'key_pair platform reader'
  end

end
