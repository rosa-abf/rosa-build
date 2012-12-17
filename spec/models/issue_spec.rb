# -*- encoding : utf-8 -*-
require 'spec_helper'

def set_data
  @user = FactoryGirl.create(:user)
  @stranger = FactoryGirl.create(:user)
end

def create_issue issue_owner
  ActionMailer::Base.deliveries = []
  @issue = FactoryGirl.create(:issue, :project_id => @project.id,
                              :user => issue_owner, :assignee => nil)
end

describe Issue do
  before do
    stub_symlink_methods
    any_instance_of(Project, :versions => ['v1.0', 'v2.0'])
  end
  context 'for project admin user' do
    before(:each) do
      set_data
      @project = FactoryGirl.create(:project, :owner => @user)
      create_issue(@stranger)
    end

    it 'should send an e-mail' do
      ActionMailer::Base.deliveries.count.should == 1
      ActionMailer::Base.deliveries.last.to.include?(@user.email).should == true
    end
  end

  context 'for member-group' do
    before(:each) do
      set_data
      @project = FactoryGirl.create(:project, :owner => @user)

      @group = FactoryGirl.create(:group)
      reader = FactoryGirl.create :user
      @group.actors.create(:actor_type => 'User', :actor_id => reader.id, :role => 'reader')
    end

    it 'should send an e-mail to all members of the admin group' do
      @project.relations.create!(:actor_type => 'Group', :actor_id => @group.id, :role => 'admin')

      create_issue(@stranger)
      ActionMailer::Base.deliveries.count.should == 3 # 1 owner + 2 group member. enough?
    end

    it 'should not send an e-mail to members of the reader group' do
      @project.relations.create!(:actor_type => 'Group', :actor_id => @group.id, :role => 'reader')

      create_issue(@stranger)
      ActionMailer::Base.deliveries.count.should == 1 # 1 project owner
    end
  end

  context 'Group project' do
    before(:each) do
      set_data
      @group = FactoryGirl.create(:group, :owner => @user)
      @project = FactoryGirl.create(:project, :owner => @group)
    end

    context 'for admin of the group' do
      it 'should send an e-mail' do
        create_issue(@stranger)
        ActionMailer::Base.deliveries.count.should == 1
        ActionMailer::Base.deliveries.last.to.include?(@user.email).should == true
      end
    end

    context 'for reader of the group' do
      it 'should not send an e-mail' do
        reader = FactoryGirl.create :user
        @group.actors.create(:actor_type => 'User', :actor_id => reader.id, :role => 'reader')

        create_issue(@stranger)
        ActionMailer::Base.deliveries.count.should == 1
      end
    end
  end
end
