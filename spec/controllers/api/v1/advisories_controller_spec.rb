require 'spec_helper'

shared_examples_for 'api advisories user with show rights' do
  it 'should be able to perform show action' do
    get :show, id: @advisory.advisory_id, format: :json
    response.should be_success
  end

  it 'should be able to perform index action' do
    get :index, format: :json
    response.should be_success
  end
end

shared_examples_for 'api advisories user with admin rights' do
  context 'api advisories user with create rights' do
    let(:params) {{ build_list_id: @build_list.id, advisory: { description: 'test' }, format: :json }}
    it 'should be able to perform create action' do
      post :create, params
      response.should be_success
    end
    it 'ensures that advisory has been created' do
      lambda { post :create, params }.should change{ Advisory.count }.by(1)
    end
    it 'ensures that build_list has been associated with advisory' do
      post :create, params
      @build_list.reload
      @build_list.advisory.should_not be_nil
    end
  end

  context 'api advisories user with update rights' do
    let(:params) {{ id: @advisory.advisory_id, build_list_id: @build_list.id, format: :json }}
    it 'should be able to perform update action' do
      put :update, params
      response.should be_success
    end
    it 'ensures that advisory has not been created' do
      lambda { put :update, params }.should_not change{ Advisory.count }
    end
    it 'ensures that build_list has been associated with advisory' do
      put :update, params
      @build_list.reload
      @build_list.advisory.should_not be_nil
    end
  end
end

shared_examples_for 'api advisories user without admin rights' do
  context 'api advisories user without create rights' do
    let(:params) {{ build_list_id: @build_list.id, advisory: { description: 'test' }, format: :json }}
    it 'should not be able to perform create action' do
      post :create, params
      response.should_not be_success
    end
    it 'ensures that advisory has not been created' do
      lambda { post :create, params }.should_not change{ Advisory.count }
    end
    it 'ensures that build_list has not been associated with advisory' do
      post :create, params
      @build_list.reload
      @build_list.advisory.should be_nil
    end
  end

  context 'api advisories user without update rights' do
    let(:params) {{ id: @advisory.advisory_id, build_list_id: @build_list.id, format: :json }}
    it 'should not be able to perform update action' do
      put :update, params
      response.should_not be_success
    end
    it 'ensures that advisory has not been created' do
      lambda { put :update, params }.should_not change{ Advisory.count }
    end
    it 'ensures that build_list has not been associated with advisory' do
      put :update, params
      @build_list.reload
      @build_list.advisory.should be_nil
    end
  end
end

describe Api::V1::AdvisoriesController do

  before do
    stub_symlink_methods

    @advisory = FactoryGirl.create(:advisory)
    @build_list = FactoryGirl.create(:build_list)
    @build_list.save_to_platform.update_column(:released, true)
    @build_list.save_to_repository.update_column(:publish_without_qa, false)
    @build_list.update_column(:status, BuildList::BUILD_PUBLISHED)
  end

  context 'for guest' do

    if APP_CONFIG['anonymous_access']
      it_should_behave_like 'api advisories user with show rights'
    end

    it 'should not be able to perform show action', :anonymous_access  => false do
      get :show, id: @advisory.advisory_id, format: :json
      response.should_not be_success
    end

    it 'should not be able to perform index action', :anonymous_access  => false do
      get :index, format: :json
      response.should_not be_success
    end
    it_should_behave_like 'api advisories user without admin rights'
  end

  context 'for simple user' do
    before do
      @user = FactoryGirl.create(:user)
      http_login(@user)
    end
    it_should_behave_like 'api advisories user with show rights'
    it_should_behave_like 'api advisories user without admin rights'
  end

  context 'for admin' do
    before do
      @admin = FactoryGirl.create(:admin)
      http_login(@admin)
    end

    it_should_behave_like 'api advisories user with show rights'
    it_should_behave_like 'api advisories user with admin rights'
  end

  context 'for user who has access to update build_list' do
    before do
      @user = FactoryGirl.create(:user)
      create_relation @build_list.save_to_platform, @user, 'admin'
      http_login(@user)
    end

    it_should_behave_like 'api advisories user with show rights'
    it_should_behave_like 'api advisories user with admin rights'
  end

end
