require 'spec_helper'

def set_data
  @user = FactoryGirl.create(:user)
  @stranger = FactoryGirl.create(:user)
end

def create_issue issue_owner
  ActionMailer::Base.deliveries = []
  @issue = FactoryGirl.create(:issue, project_id: @project.id,
                              user: issue_owner, assignee: nil)
end

describe Issue do
  before do
    stub_symlink_methods
    allow_any_instance_of(Project).to receive(:versions).and_return(%w(v1.0 v2.0))
  end


  context '#update_statistic' do
    it 'updates styatistics' do
      expect do
        FactoryGirl.create(:issue)
      end.to change(Statistic, :count).by(1)
    end
  end

  context 'for project admin user' do
    before(:each) do
      set_data
      @project = FactoryGirl.create(:project, owner: @user)
    end

    it 'should send an e-mail' do
      create_issue(@stranger)
      ActionMailer::Base.deliveries.count.should == 1
      ActionMailer::Base.deliveries.last.to.include?(@user.email).should == true
    end

    it 'should not send an e-mail to creator' do
      create_issue(@user)
      ActionMailer::Base.deliveries.count.should == 0
    end

    it 'should create automatic comment from another issue' do
      create_issue(@user)
      another_issue = FactoryGirl.create(:issue, project: @project, title: "[##{@issue.serial_id}]")
      Comment.where(automatic: true, commentable_type: 'Issue',
                    created_from_issue_id: another_issue.id).count.should == 1
    end

    it 'should create automatic comment after updating another issue body' do
      create_issue(@user)
      another_issue = FactoryGirl.create(:issue, project: @project)
      another_issue = Issue.find another_issue.id
      another_issue.update_attribute(:title, "[##{@issue.serial_id}]")

      Comment.where(automatic: true, commentable_type: 'Issue',
                    created_from_issue_id: another_issue.id).count.should == 1
    end

    it 'should send email message to new assignee' do
      create_issue(@user)
      ActionMailer::Base.deliveries = []
      @issue = Issue.find @issue.id
      @issue.update_attribute :assignee_id, @user.id

      ActionMailer::Base.deliveries.count.should == 1
    end
  end

  context 'for member-group' do
    before(:each) do
      set_data
      @project = FactoryGirl.create(:project, owner: @user)

      @group = FactoryGirl.create(:group)
      @reader = FactoryGirl.create :user
      create_actor_relation(@group, @reader, 'reader')
    end

    it 'should send an e-mail to all members of the admin group' do
      create_relation(@project, @group, 'admin')

      create_issue(@stranger)
      ActionMailer::Base.deliveries.count.should == 3 # 1 owner + 2 group member. enough?
    end

    it 'should send an e-mail to all members of the admin group except creator' do
      create_relation(@project, @group, 'admin')

      create_issue(@group.owner)
      ActionMailer::Base.deliveries.count.should == 2 # 1 owner + 1 group member. enough?
    end

    it 'should not send an e-mail to members of the reader group' do
      create_relation(@project, @group, 'reader')

      create_issue(@stranger)
      ActionMailer::Base.deliveries.count.should == 1 # 1 project owner
    end

    it 'should reset issue assignee after remove him from group' do
      create_relation(@project, @group, 'reader')
      create_issue(@group.owner)
      @issue.update_column :assignee_id, @reader.id
      @group.remove_member @reader
      @issue.reload.assignee_id.should == nil
    end

    it 'should not reset issue assignee' do
      create_relation(@project, @group, 'reader')
      create_relation(@project, @reader, 'reader')
      create_issue(@group.owner)
      @issue.update_column :assignee_id, @reader.id
      @group.remove_member @reader
      @issue.reload.assignee_id.should == @reader.id
    end

    it 'should reset issue assignee after remove him from project' do
      create_relation(@project, @reader, 'reader')
      create_issue(@reader)
      @issue.update_column :assignee_id, @reader.id
      @project.remove_member @reader # via api
      @issue.reload.assignee_id.should == nil
    end

  end

  context 'Group project' do
    before(:each) do
      set_data
      @group = FactoryGirl.create(:group, owner: @user)
      @project = FactoryGirl.create(:project, owner: @group)
    end

    context 'for admin of the group' do
      it 'should send an e-mail' do
        create_issue(@stranger)
        ActionMailer::Base.deliveries.count.should == 1
        ActionMailer::Base.deliveries.last.to.include?(@user.email).should == true
      end

      it 'should not send an e-mail to creator' do
        create_issue(@user)
        ActionMailer::Base.deliveries.count.should == 0
      end
    end

    context 'for reader of the group' do
      it 'should not send an e-mail' do
        reader = FactoryGirl.create :user
        create_actor_relation(@group, reader, 'reader')

        create_issue(@stranger)
        ActionMailer::Base.deliveries.count.should == 1
      end
    end
  end
end
