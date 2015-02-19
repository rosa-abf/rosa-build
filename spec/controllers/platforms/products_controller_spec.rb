require 'spec_helper'

shared_examples_for 'admin user' do

  it 'should be able to create product' do
    lambda { post :create, @create_params }.should change{ Product.count }.by(1)
    response.should redirect_to(platform_product_path( Product.last.platform, Product.last ))
  end

  it 'should be able to update product' do
    put :update, {id: @product.id}.merge(@update_params)
    response.should redirect_to platform_product_path(@platform, @product)
    @product.reload
    @product.name.should eql('pro2')
  end

  it 'should be able to destroy product' do
    lambda { delete :destroy, id: @product.id, platform_id: @platform }.should change{ Product.count }.by(-1)
    response.should redirect_to(platform_products_path(@platform))
  end

end

describe Platforms::ProductsController, type: :controller do
    before(:each) do
      stub_symlink_methods

      @another_user = FactoryGirl.create(:user)
      @platform = FactoryGirl.create(:platform)
      @product = FactoryGirl.create(:product, platform: @platform)
      @project = FactoryGirl.create(:project)

      params = {platform_id: @platform}
      @create_params = params.merge({product: {name: 'pro', time_living: 150, project_id: @project.id}})
      @update_params = params.merge({product: {name: 'pro2'}})

      @user = FactoryGirl.create(:user)
      set_session_for(@user)
    end

  context 'for guest' do
    before(:each) do
      set_session_for(User.new)
    end

    [:create].each do |action|
      it "should not be able to perform #{ action } action" do
        get action, platform_id: @platform.id
        response.should redirect_to(new_user_session_path)
      end
    end

    [:new, :edit, :update, :destroy].each do |action|
      it "should not be able to perform #{ action } action" do
        get action, id: @product.id, platform_id: @platform.id
        response.should redirect_to(new_user_session_path)
      end
    end

    [:show, :index].each do |action|
      it "should not be able to perform #{ action } action", anonymous_access: false do
        get action, id: @product.id, platform_id: @platform.id
        response.should redirect_to(new_user_session_path)
      end
    end

    [:show, :index].each do |action|
      it "should be able to perform #{ action } action", anonymous_access: true do
        get action, id: @product.id, platform_id: @platform.id
        response.should render_template(action)
        response.should be_success
      end
    end
  end

  context 'for global admin' do
    before(:each) do
      @user.role = "admin"
      @user.save
    end

    it_should_behave_like 'admin user'
  end

  context 'for platform owner' do
    before(:each) do
      @user = @platform.owner
      set_session_for(@user)
    end

    it_should_behave_like 'admin user'
  end

  context 'for admin relation user' do
    before(:each) do
      create_relation(@platform, @user, 'admin')
    end

    it_should_behave_like 'admin user'
  end

  context 'for no relation user' do

    it 'should not be able to create product' do
      lambda { post :create, @create_params }.should change{ Product.count }.by(0)
      response.should redirect_to(forbidden_path)
    end

    it 'should not be able to perform update action' do
      put :update, {id: @product.id}.merge(@update_params)
      response.should redirect_to(forbidden_path)
    end

    it 'should not be able to destroy product' do
      lambda { delete :destroy, id: @product.id, platform_id: @platform }.should change{ Product.count }.by(0)
      response.should redirect_to(forbidden_path)
    end

  end

end
