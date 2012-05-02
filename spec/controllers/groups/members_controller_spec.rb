# -*- encoding : utf-8 -*-
require 'spec_helper'

describe Groups::MembersController do
  before(:each) do
    stub_rsync_methods
    @group = FactoryGirl.create(:group)
    @user = @group.owner
    set_session_for @user
    @another_user = FactoryGirl.create(:user)
    @add_params = {:group_id => @group, :user_id => @another_user.uname}
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
    end
  end
end
