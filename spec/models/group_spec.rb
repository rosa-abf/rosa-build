require 'spec_helper'
require "cancan/matchers"

describe Group do
  before(:each) do
    stub_symlink_methods
    @group = FactoryGirl.create(:group)
    @ability = Ability.new(User.new)
  end

  context 'for guest' do
    [:read, :update, :destroy, :manage_members].each do |action|
      it "should not be able to #{action} group" do
        @ability.should_not be_able_to(action, @group)
      end
    end
  end

  context 'for global admin' do
    before(:each) do
      @admin = FactoryGirl.create(:admin)
      @ability = Ability.new(@admin)
    end

    [:read, :update, :destroy, :manage_members].each do |action|
      it "should be able to #{action} group" do
        @ability.should be_able_to(action, @group)
      end
    end
  end

  context 'for group admin' do
    before(:each) do
      @user = FactoryGirl.create(:user)
      @another_user = FactoryGirl.create(:user)
      @group.actors.create(:actor_type => 'User', :actor_id => @user.id, :role => 'admin')
      @ability = Ability.new(@user)
    end

    [:read, :update, :manage_members].each do |action|
      it "should be able to #{action} group" do
        @ability.should be_able_to(action, @group)
      end
    end

    it "should not be able to destroy group" do
      @ability.should_not be_able_to(:destroy, @group)
    end

    context 'with mass assignment' do
      it 'should not be able to update uname' do
        @group.should_not allow_mass_assignment_of :uname => 'new_uname'
      end

      it 'should not be able to update owner' do
        @group.should_not allow_mass_assignment_of :owner_type => 'User', :owner_id => @another_user.id
      end
    end
  end

  context 'for group owner' do
    before(:each) do
      @user = FactoryGirl.create(:user)

      @group.owner = @user
      @group.save

      @group.actors.create(:actor_type => 'User', :actor_id => @user.id, :role => 'admin')
      @ability = Ability.new(@user)
    end

    [:read, :update, :destroy, :manage_members].each do |action|
      it "should be able to #{action} group" do
        @ability.should be_able_to(action, @group)
      end
    end
  end

  context 'for group reader and writer user' do
    before(:each) do
      @user = FactoryGirl.create(:user)
      @group.actors.create(:actor_type => 'User', :actor_id => @user.id, :role => 'reader')
      @ability = Ability.new(@user)
    end

    [:read].each do |action|
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

  it {should_not allow_value("How do you do...\nmy_group").for(:uname)}
end
