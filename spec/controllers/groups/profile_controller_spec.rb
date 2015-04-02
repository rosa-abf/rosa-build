require 'spec_helper'

shared_examples_for 'group user with project show rights' do
  it 'should be able to perform show action' do
    get :show, uname: @group.uname
    expect(response).to render_template(:show)
  end
end

shared_examples_for 'group user without update rights' do
  it 'should be not able to perform update action' do
    put :update, {id: @group}.merge(@update_params)
    expect(response).to redirect_to(forbidden_path)
    expect(@group.reload.description).to_not eq 'grp2'
  end
end

shared_examples_for 'group user without destroy rights' do
  it 'should not be able to destroy group' do
    delete :destroy, id: @group
    expect(response).to redirect_to(forbidden_path)
  end

  it 'should not change groups count after destroy action' do
    expect do
      delete :destroy, id: @group
    end.to_not change(Group, :count)
  end
end

shared_examples_for 'group admin' do
  it_should_behave_like 'no group user'

  it 'should be able to perform update action' do
    put :update, {id: @group}.merge(@update_params)
    expect(response).to redirect_to(group_path(@group))
    expect(@group.reload.description).to eq 'grp2'
  end
end

shared_examples_for 'no group user' do
  it 'should be able to perform create action' do
    post :create, @create_params
    expect(response).to redirect_to(group_path(Group.last))
  end

  it 'should change objects count on create' do
    expect do
      post :create, @create_params
    end.to change(Group, :count).by(1)
  end
end

shared_examples_for 'group owner' do
  it_should_behave_like 'group admin'

  it 'should be able to destroy group' do
    delete :destroy, id: @group
    expect(response).to redirect_to(groups_path)
  end

  it 'should change groups count after destroy action' do
    expect do
      delete :destroy, id: @group
    end.to change(Group, :count).by(-1)
  end
end

describe Groups::ProfileController, type: :controller do
  before(:each) do
    stub_symlink_methods
    @group = FactoryGirl.create(:group)
    @another_user  = FactoryGirl.create(:user)
    @create_params = {group: {description: 'grp1', uname: 'un_grp1'}}
    @update_params = {group: {description: 'grp2'}}
  end

  context 'for guest' do

    if APP_CONFIG['anonymous_access']
      it_should_behave_like 'group user with project show rights'
    else
      it 'should not be able to perform show action' do
        get :show, id: @group
        expect(response).to redirect_to(new_user_session_path)
      end
    end

    it 'should not be able to perform index action' do
      get :index
      expect(response).to redirect_to(new_user_session_path)
    end

    it 'should not be able to perform update action' do
      put :update, {id: @group}.merge(@update_params)
      expect(response).to redirect_to(new_user_session_path)
    end

    it 'should not be able to perform create action' do
      post :create, @create_params
      expect(response).to redirect_to(new_user_session_path)
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
      expect(response).to render_template(:index)
    end

    it 'should be able to perform update action' do
      put :update, {id: @group}.merge(@update_params)
      expect(response).to redirect_to(group_path(@group))
    end
  end

  context 'for group admin' do
    before(:each) do
      @user = FactoryGirl.create(:user)
      set_session_for(@user)
      create_actor_relation(@group, @user, 'admin')
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
      create_actor_relation(@group, @user, 'admin')
    end

    it_should_behave_like 'group user with project show rights'
    it_should_behave_like 'update_member_relation'
    it_should_behave_like 'group owner'
  end

  context 'for group reader and writer user' do
    before(:each) do
      @user = FactoryGirl.create(:user)
      set_session_for(@user)
      create_actor_relation(@group, @user, 'reader')
    end

    it "should remove user from groups" do
      delete :remove_user, id: @group
      expect(response).to redirect_to(groups_path)
    end

    it "should change relations count" do
      expect do
        delete :remove_user, id: @group
      end.to change(Relation, :count).by(-1)
    end

    it_should_behave_like 'group user with project show rights'
    it_should_behave_like 'no group user'
    it_should_behave_like 'group user without destroy rights'
    it_should_behave_like 'group user without update rights'
  end
end
