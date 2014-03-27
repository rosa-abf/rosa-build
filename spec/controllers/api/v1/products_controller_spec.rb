require 'spec_helper'

shared_examples_for 'api user without reader rights' do
  it 'should not be able to perform show action', :anonymous_access  => false do
    get :show, id: @product.id, format: :json
    response.status.should == 401
  end

  it 'should be able to perform show action', :anonymous_access  => true do
    get :show, id: @product.id, format: :json
    response.should be_success
  end

  it 'should not be able to perform show action for the hidden platform', :anonymous_access  => true do
    @product.platform.update_column :visibility, 'hidden'
    get :show, id: @product.id, format: :json
    response.status.should == 403
  end

  it 'should not be able to perform create action' do
    post :create, format: :json
    response.status.should == 401
  end

  [:update, :destroy].each do |action|
    it "should not be able to perform #{action} action" do
      put action, id: @product.id, format: :json
      response.status.should == 401
    end
  end
end

shared_examples_for 'api user with reader rights' do
  it 'should be able to perform show action' do
    get :show, id: @product.id, format: :json
    response.should be_success
  end

  it 'should be able to perform show action for the hidden main platform' do
    @product.platform.update_column :visibility, 'hidden'
    get :show, id: @product.id, format: :json
    response.should be_success # because main platform
  end

  it 'should not be able to perform create action' do
    post :create, format: :json
    response.status.should == 403
  end

  [:update, :destroy].each do |action|
    it "should not be able to perform #{action} action" do
      put action, id: @product.id, format: :json
      response.status.should == 403
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
    response.should be_success
  end

  it 'should be able to perform show action for the hidden platform' do
    @product.platform.update_column :visibility, 'hidden'
    get :show, id: @product.id, format: :json
    response.should be_success
  end

  it 'should be able to perform create action' do
    post :create, @create_params, format: :json
    response.should be_success
  end

  it 'ensures that product has been created' do
    lambda { post :create, @create_params, format: :json }.should change{ Product.count }.by(1)
  end

  [:update, :destroy].each do |action|
    it "should be able to perform #{action} action" do
      put action, id: @product.id, format: :json
      response.should be_success
    end
  end

  it "ensures that product has been destroyed" do
    lambda { put :destroy, id: @product.id, format: :json }.should change{ Product.count }.by(-1)
  end

  it "ensures that product has been updated" do
    put :update, @update_params.merge(id: @product.id), format: :json
    @product.reload.name.should == 'pro2'
    @product.reload.time_living.should == 250*60 # in seconds
  end

  it 'ensures that return correct answer for wrong creating action' do
    post :create, format: :json
    response.status.should == 403 # Maybe 422?
  end

  #[:update, :destroy].each do |action|
  #  it "ensures that return correct answer for wrong #{action} action" do
  #    put action, id: nil, format: :json
  #    response.status.should == 404
  #  end
  #end
end

describe Api::V1::ProductsController do
  before(:each) do
    stub_symlink_methods

    @product = FactoryGirl.create(:product)
    @another_user = FactoryGirl.create(:user)
  end

  context 'for guest' do
    it_should_behave_like 'api user without reader rights'


  end

  context 'for user' do
    before(:each) do
      http_login(@another_user)
    end

    it_should_behave_like 'api user with reader rights'
  end

  context 'for platform admin' do
    it_should_behave_like 'api user with admin rights'
  end
end
