require 'spec_helper'

describe ProductsController do
	before(:each) do
    @another_user = Factory(:user)
    @platform = Factory(:platform)
    @product = Factory(:product, :platform => @platform)
    @create_params = {:product => {:name => 'pro'}, :platform_id => @platform.id}
    @update_params = {:product => {:name => 'pro2'}, :platform_id => @platform.id}
	end

	context 'for guest' do
    [:create].each do |action|
      it "should not be able to perform #{ action } action" do
        get action, :platform_id => @platform.id
        response.should redirect_to(new_user_session_path)
      end
    end

    [:show, :new, :edit, :update, :destroy].each do |action|
      it "should not be able to perform #{ action } action" do
        get action, :id => @product.id, :platform_id => @platform.id
        response.should redirect_to(new_user_session_path)
      end
    end
  end

  context 'for global admin' do
  	before(:each) do
  		@admin = Factory(:admin)
  		set_session_for(@admin)
		end

    it 'should be able to perform create action' do
      post :create, @create_params
      response.should redirect_to(platform_path( Product.last.platform.id ))
    end

    it 'should change objects count on create' do
      lambda { post :create, @create_params }.should change{ Product.count }.by(1)
    end

    it 'should be able to perform update action' do
      put :update, {:id => @product.id}.merge(@update_params)
      response.should redirect_to(platform_path(@platform))
    end

    it 'should change objects count on destroy success' do
      lambda { delete :destroy, :id => @product.id, :platform_id => @platform }.should change{ Product.count }.by(-1)
    end

    it 'should be able to perform destroy action' do
      delete :destroy, :platform_id => @platform.id, :id => @product.id
      response.should redirect_to(platform_path(@platform))
    end
  end

  context 'for admin relation user' do
  	before(:each) do
  		@user = Factory(:user)
  		set_session_for(@user)
      r = @product.relations.create!(:object_type => 'User', :object_id => @user.id, :role => 'admin')
      r = @platform.relations.create!(:object_type => 'User', :object_id => @user.id, :role => 'admin')
		end

    it 'should be able to perform create action' do
      post :create, @create_params
      response.should redirect_to(platform_path( Product.last.platform.id ))
    end

    it 'should change objects count on create' do
      lambda { post :create, @create_params }.should change{ Product.count }.by(1)
    end

    it 'should be able to perform update action' do
      put :update, {:id => @product.id}.merge(@update_params)
      response.should redirect_to(platform_path(@platform))
    end

    it 'should change objects count on destroy success' do
      lambda { delete :destroy, :id => @product.id, :platform_id => @platform }.should change{ Product.count }.by(-1)
    end

    it 'should be able to perform destroy action' do
      delete :destroy, :platform_id => @platform.id, :id => @product.id
      response.should redirect_to(platform_path(@platform))
    end
  end

  context 'for no relation user' do
  	before(:each) do
  		@user = Factory(:user)
  		set_session_for(@user)
		end

    it 'should not be able to perform create action' do
      post :create, @create_params
      response.should redirect_to(forbidden_path)
    end

    it 'should not change objects count on create' do
      lambda { post :create, @create_params }.should change{ Product.count }.by(0)
    end

    it 'should not be able to perform update action' do
      put :update, {:id => @product.id}.merge(@update_params)
      response.should redirect_to(forbidden_path)
    end

    it 'should not change objects count on destroy success' do
      lambda { delete :destroy, :id => @product.id, :platform_id => @platform }.should change{ Product.count }.by(0)
    end

    it 'should not be able to perform destroy action' do
      delete :destroy, :platform_id => @platform.id, :id => @product.id
      response.should redirect_to(forbidden_path)
    end
  end

end
