# -*- encoding : utf-8 -*-
require 'spec_helper'

describe MembersController do
  before(:each) do
    @group = Factory(:group)
    @user = @group.owner
    set_session_for @user
    @another_user = Factory(:user)
    @add_params = {:group_id => @group.id, :user_id => @another_user.uname}
  end

  context 'for owner user' do
    it 'should add member to group' do
      post :add, @add_params
      response.should redirect_to(edit_group_members_path(@group))
      Relation.by_target(@group).by_object(@another_user).count.should eql(1)
    end

    it 'should add reader member to group' do
      post :add, @add_params
      Relation.by_target(@group).by_object(@another_user).first.role.should eql('reader')
    end
  end
end
