require 'spec_helper'
require "cancan/matchers"

def set_testable_data
  @ability = Ability.new(@user)

  @project = FactoryGirl.create(:project)
  @issue = FactoryGirl.create(:issue, :project_id => @project.id)

  any_instance_of(Project, :versions => ['v1.0', 'v2.0'])
end

describe Subscribe do
  before { stub_symlink_methods }
  context 'for global admin user' do
    before(:each) do
      @user = FactoryGirl.create(:admin)
      @stranger = FactoryGirl.create(:user)

      set_testable_data
    end

    it 'should create subscribe' do
      @ability.should be_able_to(:create, Subscribe.new(:subscribeable => @issue, :user => @user))
    end

    context 'destroy' do
      before(:each) do
        @subscribe = FactoryGirl.create(:subscribe, :subscribeable => @issue, :user => @user)
        @stranger_subscribe = FactoryGirl.create(:subscribe, :subscribeable => @issue, :user => @stranger)
      end

      context 'own subscribe' do
        it 'should destroy subscribe' do
          @ability.should be_able_to(:destroy, @subscribe)
        end
      end

      context 'stranger subscribe' do
        it 'should not destroy subscribe' do
          @ability.should_not be_able_to(:destroy, @stranger_subscribe)
        end
      end
    end
  end

  context 'for simple user' do
    before(:each) do
      @user = FactoryGirl.create(:user)
      @stranger = FactoryGirl.create(:user)

      set_testable_data
    end

    it 'should create subscribe' do
      @ability.should be_able_to(:create, Subscribe.new(:subscribeable => @issue, :user => @user))
    end

    context 'destroy' do
      before(:each) do
        @subscribe = FactoryGirl.create(:subscribe, :subscribeable => @issue, :user => @user)
        @stranger_subscribe = FactoryGirl.create(:subscribe, :subscribeable => @issue, :user => @stranger)
      end

      context 'own subscribe' do
        it 'should destroy subscribe' do
          @ability.should be_able_to(:destroy, @subscribe)
        end
      end

      context 'stranger subscribe' do
        it 'should not destroy subscribe' do
          @ability.should_not be_able_to(:destroy, @stranger_subscribe)
        end
      end
    end
  end
end
