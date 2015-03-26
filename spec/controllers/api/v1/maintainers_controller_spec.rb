require 'spec_helper'

shared_examples_for 'api maintainers user with reader rights' do
  it 'should be able to perform index action' do
    get :index, platform_id: package.platform_id, format: :json
    expect(response).to render_template(:index)
  end

  it 'loads all of the maintainers into @maintainers' do
    get :index, platform_id: package.platform_id, format: :json
    expect(assigns(:maintainers).count).to eq 2
    expect(assigns :maintainers).to include(package, package2)
  end

  it 'loads all of the maintainers into @maintainers when search by name' do
    get :index, platform_id: package.platform_id, package_name: 'package1', format: :json
    expect(assigns(:maintainers).count).to eq 1
    expect(assigns :maintainers).to include(package)
  end

end

describe Api::V1::MaintainersController, type: :controller do
  before do
    stub_symlink_methods
    FactoryGirl.create(:build_list_package, platform: package.platform)
  end
  let(:package)   { FactoryGirl.create(:build_list_package, name: 'package1', actual: true) }
  let!(:package2) { FactoryGirl.create(:build_list_package, platform: package.platform, actual: true) }


  context 'for guest' do
    if APP_CONFIG['anonymous_access']
      it_should_behave_like 'api maintainers user with reader rights'
    else
      it 'should not be able to perform index action', :anonymous_access  => false do
        get :index, platform_id: package.platform_id, format: :json
        expect(response.status).to eq 401
      end
    end
  end

  context 'for simple user' do
    before do
      http_login(FactoryGirl.create(:user))
    end

    it_should_behave_like 'api maintainers user with reader rights'
  end
end
