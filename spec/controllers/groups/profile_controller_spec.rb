# -*- encoding : utf-8 -*-
require 'spec_helper'

shared_examples_for 'group user with project show rights' do
  it 'should be able to perform show action' do
    get :show, :uname => @group.uname
    response.should render_template(:show)
  end
end

shared_examples_for 'group user without update rights' do
  it 'should be not able to perform update action' do
    put :update, {:id => @group}.merge(@update_params)
    response.should redirect_to(forbidden_path)
  end

  it 'should not be able to update group data' do
    put :update, :id => @group, :group => {:description => 'new description'}
    @group.reload.description.should_not == 'new description'
  end
end

shared_examples_for 'group user without destroy rights' do
  it 'should not be able to destroy group' do
    delete :destroy, :id => @group
    response.should redirect_to(forbidden_path)
  end

  it 'should not change groups count after destroy action' do
    lambda { delete :destroy, :id => @group }.should change{ Group.count }.by(0)
  end
end

shared_examples_for 'group admin' do
  it_should_behave_like 'no group user'

  it 'should be able to update group data' do
    put :update, :id => @group, :group => {:description => 'new description'}
    @group.reload.description.should == 'new description'
  end

  it 'should be able to perform update action' do
    put :update, {:id => @group}.merge(@update_params)
    response.should redirect_to(group_path(@group))
  end
end

shared_examples_for 'no group user' do
  it 'should be able to perform create action' do
    post :create, @create_params
    response.should redirect_to(group_path(Group.last))
  end

  it 'should change objects count on create' do
    lambda { post :create, @create_params }.should change{ Group.count }.by(1)
  end
end

shared_examples_for 'group owner' do
  it_should_behave_like 'group admin'

  it 'should be able to destroy group' do
    delete :destroy, :id => @group
    response.should redirect_to(groups_path)
  end

  it 'should change groups count after destroy action' do
    lambda { delete :destroy, :id => @group }.should change{ Group.count }.by(-1)
  end
end

describe Groups::ProfileController do
  before(:each) do
    stub_symlink_methods
    @group = FactoryGirl.create(:group)
    @another_user  = FactoryGirl.create(:user)
    @create_params = {:group => {:description => 'grp1', :uname => 'un_grp1'}}
    @update_params = {:group => {:description => 'grp2'}}
  end

  context 'for guest' do

    if APP_CONFIG['anonymous_access']
      it_should_behave_like 'group user with project show rights'
    else
      it 'should not be able to perform show action' do
        get :show, :id => @group
        response.should redirect_to(new_user_session_path)
      end
    end

    it 'should not be able to perform index action' do
      get :index
      response.should redirect_to(new_user_session_path)
    end

    it 'should not be able to perform update action' do
      put :update, {:id => @group}.merge(@update_params)
      response.should redirect_to(new_user_session_path)
    end

    it 'should not be able to perform create action' do
      post :create, @create_params
      response.should redirect_to(new_user_session_path)
    end
  end

  context 'for global admin' do
    before(:each) do
      @admin = FactoryGirl.create(:admin)
      set_session_for(@admin)
    end

    it_should_behave_like 'group user with project show rights'
    it_should_behave_like 'update_member_relation'
    it_should_behave_like 'group owner'

    it 'should be able to perform index action' do
      get :index
      response.should render_template(:index)
    end

    it 'should be able to perform update action' do
      put :update, {:id => @group}.merge(@update_params)
      response.should redirect_to(group_path(@group))
    end
  end

  context 'for group admin' do
    before(:each) do
      @user = FactoryGirl.create(:user)
      set_session_for(@user)
      @group.actors.create(:actor_type => 'User', :actor_id => @user.id, :role => 'admin')
    end

    it_should_behave_like 'group user with project show rights'
    it_should_behave_like 'update_member_relation'
    it_should_behave_like 'group admin'
    it_should_behave_like 'group user without destroy rights'
  end

  context 'for group owner' do
    before(:each) do
      @user = FactoryGirl.create(:user)
      set_session_for(@user)
      @group.owner = @user
      @group.save
      @group.actors.create(:actor_type => 'User', :actor_id => @user.id, :role => 'admin')
    end

    it_should_behave_like 'group user with project show rights'
    it_should_behave_like 'update_member_relation'
    it_should_behave_like 'group owner'
  end

  context 'for group reader and writer user' do
    before(:each) do
      @user = FactoryGirl.create(:user)
      set_session_for(@user)
      @group.actors.create(:actor_type => 'User', :actor_id => @user.id, :role => 'reader')
    end

    it "should remove user from groups" do
      delete :remove_user, :id => @group
      response.should redirect_to(groups_path)
    end

    it "should change relations count" do
      lambda { delete :remove_user, :id => @group }.should change{ Relation.count }.by(-1)
    end

    it_should_behave_like 'group user with project show rights'
    it_should_behave_like 'no group user'
    it_should_behave_like 'group user without destroy rights'
    it_should_behave_like 'group user without update rights'
  end
end
