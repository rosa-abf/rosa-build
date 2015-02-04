require 'spec_helper'

describe Groups::MembersController do
  before(:each) do
    stub_symlink_methods
    @group = FactoryGirl.create(:group)
    @user = @group.owner
    set_session_for @user
    @another_user = FactoryGirl.create(:user)
    @add_params = {group_id: @group, member_id: @another_user.id}
    @remove_params = {group_id: @group, members: [@group.owner.id]}
    @update_params = {group_id: @group, member_id: @group.owner.id, role: :reader}
  end

  context 'for owner user' do
    it 'should add member to group' do
      post :add, @add_params
      response.should redirect_to(group_members_path(@group))
      Relation.by_target(@group).by_actor(@another_user).count.should eql(1)
    end

    it 'should add reader member to group' do
      post :add, @add_params
      Relation.by_target(@group).by_actor(@another_user).first.role.should eql('reader')
      response.should redirect_to(group_members_path(@group))
    end

    it 'should not remove self from group' do
      post :remove, @remove_params
      Relation.by_target(@group).by_actor(@user).first.role.should eql('admin')
      response.should redirect_to(group_members_path(@group))
    end
  end

  context 'for admin user' do
    before(:each) do
      @admin_user = FactoryGirl.create(:user)
      create_actor_relation(@group, @admin_user, 'admin')
      set_session_for @admin_user
    end

    it 'should add member to group' do
      post :add, @add_params
      response.should redirect_to(group_members_path(@group))
      Relation.by_target(@group).by_actor(@another_user).count.should eql(1)
      response.should redirect_to(group_members_path(@group))
    end

    it 'should add reader member to group' do
      post :add, @add_params
      Relation.by_target(@group).by_actor(@another_user).first.role.should eql('reader')
      response.should redirect_to(group_members_path(@group))
    end

    it 'should not remove owner from group' do
      post :remove, @remove_params
      Relation.by_target(@group).by_actor(@user).first.role.should eql('admin')
      response.should redirect_to(group_members_path(@group))
    end

    it 'should not set read role to owner group' do
      post :update, @update_params
      Relation.by_target(@group).by_actor(@user).first.role.should eql('admin')
      response.should redirect_to(forbidden_path)
    end
  end

  context 'for writer user' do
    before(:each) do
      @writer_user = FactoryGirl.create(:user)
      create_actor_relation(@group, @writer_user, 'writer')
      set_session_for @writer_user
    end

    it 'should not add member to group' do
      post :add, @add_params
      response.should redirect_to(forbidden_path)
    end

    it 'should add reader member to group' do
      post :add, @add_params
      response.should redirect_to(forbidden_path)
    end

    it 'should not remove owner from group' do
      post :remove, @remove_params
      response.should redirect_to(forbidden_path)
    end

    it 'should not set read role to owner group' do
      post :update, @update_params
      response.should redirect_to(forbidden_path)
    end
  end

  context 'for another user' do
    before(:each) do
      set_session_for @another_user
    end

    it 'should not add member to group' do
      post :add, @add_params
      response.should redirect_to(forbidden_path)
    end

    it 'should add reader member to group' do
      post :add, @add_params
      response.should redirect_to(forbidden_path)
    end

    it 'should not remove owner from group' do
      post :remove, @remove_params
      response.should redirect_to(forbidden_path)
    end

    it 'should not set read role to owner group' do
      post :update, @update_params
      response.should redirect_to(forbidden_path)
    end
  end
end
