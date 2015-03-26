require 'spec_helper'

shared_examples_for 'api user without reader rights' do
  it 'should not be able to perform show action', :anonymous_access  => false do
    get :show, id: @product_build_list.id, format: :json
    expect(response.status).to eq 401
  end

  it 'should be able to perform show action' do
    get :show, id: @product_build_list.id, format: :json
    expect(response).to be_success
  end

  it 'should not be able to perform show action for the hidden platform' do
    @product_build_list.product.platform.update_column :visibility, 'hidden'
    get :show, id: @product_build_list.id, format: :json
    expect(response).to_not be_success
  end

  it 'should not be able to perform create action' do
    post :create, format: :json
    expect(response.status).to eq 401
  end

  [:update, :destroy].each do |action|
    it "should not be able to perform #{action} action" do
      put action, id: @product_build_list.id, format: :json
      expect(response.status).to eq 401
    end
  end
end

shared_examples_for 'api user with reader rights' do
  it 'should be able to perform show action' do
    get :show, id: @product_build_list.id, format: :json
    expect(response).to be_success
  end

  it 'should be able to perform show action for the hidden main platform' do
    allow_any_instance_of(PlatformPolicy).to receive(:show?).and_return(true)
    @product_build_list.product.platform.update_column :visibility, 'hidden'
    get :show, id: @product_build_list.id, format: :json
    expect(response).to be_success
  end

  it 'should not be able to perform create action' do
    post :create, format: :json
    expect(response.status).to eq 403
  end

  [:update, :destroy].each do |action|
    it "should not be able to perform #{action} action" do
      put action, id: @product_build_list.id, format: :json
      expect(response.status).to eq 403
    end
  end
end

shared_examples_for 'api user with admin rights' do
  before(:each) do
    create_relation(@product_build_list.product.platform, @another_user, 'admin')
    http_login(@another_user)
    commit_hash = @product_build_list.project.repo.commits.first.id
    params = {product_id: @product_build_list.product_id, arch_id: Arch.last.id,
                        commit_hash: commit_hash, main_script: @product_build_list.main_script}
    @create_params = {product_build_list:{time_living: 150}.merge(params)}
    @update_params = {product_build_list:{time_living: 250, not_delete: true}}
  end

  it 'should be able to perform show action' do
    get :show, id: @product_build_list.id, format: :json
    expect(response).to be_success
  end

  it 'should be able to perform show action for the hidden platform' do
    @product_build_list.product.platform.update_column :visibility, 'hidden'
    get :show, id: @product_build_list.id, format: :json
    expect(response).to be_success
  end

  it 'should be able to perform create action' do
    post :create, @create_params, format: :json
    expect(response).to be_success
  end

  it 'ensures that product has been created' do
    expect do
      post :create, @create_params, format: :json
    end.to change(ProductBuildList, :count).by(1)
  end

  it "should be able to perform destroy action" do
    put :destroy, id: @product_build_list.id, format: :json
    expect(response).to be_success
  end

  it "ensures that product has been destroyed" do
    expect do
      put :destroy, id: @product_build_list.id, format: :json
    end.to change(ProductBuildList, :count).by(-1)
  end

  it "should be able to perform update action" do
    put :update, @update_params.merge(id: @product_build_list.id), format: :json
    expect(response).to be_success
  end

  it "ensures that only not_delete field of product build list has been updated" do
    put :update, @update_params.merge(id: @product_build_list.id), format: :json
    expect(@product_build_list.reload.time_living).to eq 150*60 # in seconds
    expect(@product_build_list.not_delete).to be_truthy
  end

  it 'ensures that return correct answer for wrong creating action' do
    post :create, format: :json
    expect(response.status).to eq 403 # Maybe 422?
  end
end

describe Api::V1::ProductBuildListsController, type: :controller do
  before do
    stub_symlink_methods
    FactoryGirl.create(:arch, name: 'x86_64')

    @product_build_list = FactoryGirl.create(:product_build_list)
    @another_user = FactoryGirl.create(:user)
  end

  context 'for guest' do
    it_should_behave_like 'api user without reader rights'
  end

  context 'for user' do
    before do
      http_login(@another_user)
    end

    it_should_behave_like 'api user with reader rights'
  end

  context 'for platform admin' do
    it_should_behave_like 'api user with admin rights'
  end
end
