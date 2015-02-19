require 'spec_helper'

shared_examples_for 'content platform user without show rights for hidden platform' do
  it 'should not be able to perform index action' do
    @platform.update_column(:visibility, 'hidden')
    get :index, platform_id: @platform
    response.should_not be_success
  end
end

shared_examples_for 'content platform user with show rights for hidden platform' do
  it 'should be able to perform index action' do
    @platform.update_column(:visibility, 'hidden')
    get :index, platform_id: @platform
    response.should be_success
  end
end

shared_examples_for 'content platform user with show rights' do
  it 'should be able to perform index action for main platform' do
    get :index, platform_id: @platform
    response.should be_success
  end

  it 'should be able to perform index action for personal platform' do
    get :index, platform_id: @personal_platform
    response.should be_success
  end
end

shared_examples_for 'content platform user without member rights' do
  it 'should not be able to perform remove_file action for main platform' do
    get :remove_file, platform_id: @platform, path: '/test'
    response.should_not be_success
  end

  it 'should not be able to perform index remove_file for personal platform' do
    get :remove_file, platform_id: @personal_platform, path: '/test'
    response.should_not be_success
  end
end

shared_examples_for 'content platform user with member rights' do
  before do
    allow(PlatformContent).to receive(:remove_file)
  end

  it 'should be able to perform remove_file action for main platform' do
    get :remove_file, platform_id: @platform, path: '/test'
    response.should be_success
  end

  it 'should be able to perform remove_file action for personal platform' do
    get :remove_file, platform_id: @personal_platform, path: '/test'
    response.should be_success
  end
end

describe Platforms::ContentsController, type: :controller do
  before do
    stub_symlink_methods

    @platform = FactoryGirl.create(:platform)
    @personal_platform = FactoryGirl.create(:platform, platform_type: 'personal')

    @user = FactoryGirl.create(:user)
  end

  context 'for guest' do

    it 'should not be able to perform index action for main platform', anonymous_access: false do
      get :index, platform_id: @platform
      response.should_not be_success
    end

    it 'should not be able to perform index action for personal platform', anonymous_access: false do
      get :index, platform_id: @personal_platform
      response.should_not be_success
    end

    it_should_behave_like 'content platform user with show rights' if APP_CONFIG['anonymous_access']
    it_should_behave_like 'content platform user without show rights for hidden platform'
    it_should_behave_like 'content platform user without member rights'
  end

  context 'for global admin' do
    before do
      http_login(FactoryGirl.create(:admin))
    end

    it_should_behave_like 'content platform user with show rights'
    it_should_behave_like 'content platform user with show rights for hidden platform'
    it_should_behave_like 'content platform user with member rights'
  end

  context 'for member of platform' do
    before do
      http_login(@user)
      @platform.add_member(@user)
      @personal_platform.add_member(@user)
    end

    it_should_behave_like 'content platform user with show rights'
    it_should_behave_like 'content platform user with show rights for hidden platform'
    it_should_behave_like 'content platform user with member rights'
  end

  context 'for simple user' do
    before do
      http_login(@user)
    end

    it_should_behave_like 'content platform user with show rights'
    it_should_behave_like 'content platform user without show rights for hidden platform'
    it_should_behave_like 'content platform user without member rights'
  end

end
