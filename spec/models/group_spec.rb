# -*- encoding : utf-8 -*-
require 'spec_helper'
require "cancan/matchers"

describe Group do
  before(:each) do
    stub_rsync_methods
    @group = Factory(:group)
    @ability = Ability.new(User.new)
  end

  context 'for guest' do
    [:read, :update, :destroy, :manage_members, :autocomplete_group_uname].each do |action|
      it "should not be able to #{action} group" do
        @ability.should_not be_able_to(action, @group)
      end
    end
  end

  context 'for global admin' do
    before(:each) do
      @admin = Factory(:admin)
      @ability = Ability.new(@admin)
    end

    [:read, :update, :destroy, :manage_members, :autocomplete_group_uname].each do |action|
      it "should be able to #{action} group" do
        @ability.should be_able_to(action, @group)
      end
    end
  end

  context 'for group admin' do
    before(:each) do
      @user = Factory(:user)
      @group.objects.create(:object_type => 'User', :object_id => @user.id, :role => 'admin')
      @ability = Ability.new(@user)
    end

    [:read, :update, :manage_members, :autocomplete_group_uname].each do |action|
      it "should be able to #{action} group" do
        @ability.should be_able_to(action, @group)
      end
    end

    it "should not be able to destroy group" do
      @ability.should_not be_able_to(:destroy, @group)
    end
  end

  context 'for group owner' do
    before(:each) do
      @user = Factory(:user)
      @group.update_attribute(:owner, @user)
      @group.objects.create(:object_type => 'User', :object_id => @user.id, :role => 'admin')
      @ability = Ability.new(@user)
    end

    [:read, :update, :destroy, :manage_members, :autocomplete_group_uname].each do |action|
      it "should be able to #{action} group" do
        @ability.should be_able_to(action, @group)
      end
    end
  end

  context 'for group reader and writer user' do
    before(:each) do
      @user = Factory(:user)
      @group.objects.create(:object_type => 'User', :object_id => @user.id, :role => 'reader')
      @ability = Ability.new(@user)
    end

    [:read, :autocomplete_group_uname].each do |action|
      it "should be able to #{action} group" do
        @ability.should be_able_to(action, @group)
      end
    end

    [:update, :destroy, :manage_members].each do |action|
      it "should not be able to #{action} group" do
        @ability.should_not be_able_to(action, @group)
      end
    end
  end
end
