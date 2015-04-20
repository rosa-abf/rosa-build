require 'spec_helper'

shared_examples_for 'api user without reader rights' do
  it 'should not be able to perform show action', :anonymous_access  => false do
    get :show, id: @product.id, format: :json
    expect(response.status).to eq 401
  end

  it 'should be able to perform show action', :anonymous_access  => true do
    get :show, id: @product.id, format: :json
    expect(response).to be_success
  end

  it 'should not be able to perform show action for the hidden platform', :anonymous_access  => true do
    @product.platform.update_column :visibility, 'hidden'
    get :show, id: @product.id, format: :json
    expect(response.status).to eq 403
  end

  it 'should not be able to perform create action' do
    post :create, format: :json
    expect(response.status).to eq 401
  end

  [:update, :destroy].each do |action|
    it "should not be able to perform #{action} action" do
      put action, id: @product.id, format: :json
      expect(response.status).to eq 401
    end
  end
end

shared_examples_for 'api user with reader rights' do
  it 'should be able to perform show action' do
    get :show, id: @product.id, format: :json
    expect(response).to be_success
  end

  it 'should be able to perform show action for the hidden main platform' do
    allow_any_instance_of(PlatformPolicy).to receive(:show?).and_return(true)
    @product.platform.update_column :visibility, 'hidden'
    get :show, id: @product.id, format: :json
    expect(response).to be_success # because main platform
  end

  it 'should not be able to perform create action' do
    post :create, format: :json
    expect(response.status).to eq 403
  end

  [:update, :destroy].each do |action|
    it "should not be able to perform #{action} action" do
      put action, id: @product.id, format: :json
      expect(response.status).to eq 403
    end
  end
end

shared_examples_for 'api user with admin rights' do
  before(:each) do
    create_relation(@product.platform, @another_user, 'admin')
    http_login(@another_user)
    params = {platform_id: @product.platform.id, project_id: @product.project.id}
    @create_params = {product:{name: 'pro', time_living: 150}.merge(params)}
    @update_params = {product:{name: 'pro2', time_living: 250}}
  end

  it 'should be able to perform show action' do
    get :show, id: @product.id, format: :json
    expect(response).to be_success
  end

  it 'should be able to perform show action for the hidden platform' do
    @product.platform.update_column :visibility, 'hidden'
    get :show, id: @product.id, format: :json
    expect(response).to be_success
  end

  it 'should be able to perform create action' do
    post :create, @create_params, format: :json
    expect(response).to be_success
  end

  it 'ensures that product has been created' do
    expect do
      post :create, @create_params, format: :json
    end.to change(Product, :count).by(1)
  end

  [:update, :destroy].each do |action|
    it "should be able to perform #{action} action" do
      put action, id: @product.id, format: :json
      expect(response).to be_success
    end
  end

  it "ensures that product has been destroyed" do
    expect do
      put :destroy, id: @product.id, format: :json
    end.to change(Product, :count).by(-1)
  end

  it "ensures that product has been updated" do
    put :update, @update_params.merge(id: @product.id), format: :json
    expect(@product.reload.name).to eq 'pro2'
    expect(@product.reload.time_living).to eq 250*60 # in seconds
  end

  it 'ensures that return correct answer for wrong creating action' do
    post :create, format: :json
    expect(response.status).to eq 403 # Maybe 422?
  end

  #[:update, :destroy].each do |action|
  #  it "ensures that return correct answer for wrong #{action} action" do
  #    put action, id: nil, format: :json
  #    expect(response.status).to eq 404
  #  end
  #end
end

describe Api::V1::ProductsController, type: :controller do
  before do
    stub_symlink_methods

    @product = FactoryGirl.create(:product)
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
