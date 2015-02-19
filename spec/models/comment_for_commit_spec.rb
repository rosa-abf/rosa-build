require 'spec_helper'
require "cancan/matchers"

def create_comment user
  FactoryGirl.create(:comment, user: user, commentable: @commit, project: @project)
end

def create_comment_in_commit commit, project, body
  FactoryGirl.create(:comment, user: @user, commentable: commit, project: project, body: body)
end

def set_comments_data_for_commit
  @ability = Ability.new(@user)

  @project = FactoryGirl.create(:project_with_commit, owner: @user)
  @commit = @project.repo.commits.first

  @comment = create_comment(@user)
  @stranger_comment = create_comment(@stranger)

  @subscribe_params = {project_id: @project.id, subscribeable_id: @commit.id.hex, subscribeable_type: @commit.class.name}
  Subscribe.destroy_all

  allow_any_instance_of(Project).to receive(:versions).and_return(%w(v1.0 v2.0))
end

def should_send_email(args={})
  user_mailer = double(:user_mailer)
  expect(UserMailer).to receive(:new_comment_notification).with(kind_of(Comment), args[:receiver].id).and_return(user_mailer)
  expect(user_mailer).to receive(:deliver)

  create_comment args[:commentor]
end

def should_not_send_email(args={})
  expect(UserMailer).to_not receive(:new_comment_notification)
  create_comment args[:commentor]
end

describe Comment do
  before { stub_symlink_methods }
  context 'for global admin user' do
    before(:each) do
      @user = FactoryGirl.create(:admin)
      @stranger = FactoryGirl.create(:user)

      set_comments_data_for_commit
    end

    it_should_behave_like 'user with create comment ability (for model)'
    it_should_behave_like 'user with update own comment ability (for model)'
    it_should_behave_like 'user with update stranger comment ability (for model)'
    it_should_behave_like 'user with destroy comment ability (for model)'
    it_should_behave_like 'user with destroy stranger comment ability (for model)'
  end

  context 'for project admin user' do
    before do
      @user = FactoryGirl.create(:user)
      @stranger = FactoryGirl.create(:user)

      set_comments_data_for_commit
      @admin = FactoryGirl.create(:user)
      @ability = Ability.new(@admin)
      create_relation(@project, @admin, 'admin')
    end

    it_should_behave_like 'user with create comment ability (for model)'
    it_should_behave_like 'user with update own comment ability (for model)'
    it_should_behave_like 'user with update stranger comment ability (for model)'
    it_should_behave_like 'user with destroy comment ability (for model)'
    it_should_behave_like 'user with destroy stranger comment ability (for model)'

    it 'should send an e-mail by default settings' do
      should_send_email(commentor: @stranger, receiver: @user)
    end

    context 'for disabled notify setting new_comment_commit_repo_owner' do
      it 'should send an e-mail' do
        @user.notifier.update_column :new_comment_commit_repo_owner, false
        should_send_email(commentor: @stranger, receiver: @user)
      end
    end

    context 'for disabled notify setting new_comment_commit_owner' do
      it 'should send an e-mail' do
        @user.notifier.update_column :new_comment_commit_owner, false
        should_send_email(commentor: @stranger, receiver: @user)
      end
    end

    context 'for disabled notify setting new_comment_commit_commentor' do
      it 'should send an e-mail' do
        @user.notifier.update_column :new_comment_commit_commentor, false
        should_send_email(commentor: @stranger, receiver: @user)
      end
    end

    context 'for disabled all notify setting expect global' do
      it 'should not send an e-mail' do
        @user.notifier.update_column :new_comment_commit_repo_owner, false
        @user.notifier.update_column :new_comment_commit_owner, false
        @user.notifier.update_column :new_comment_commit_commentor, false
        should_not_send_email(commentor: @stranger)
      end
    end

    context 'for unsubscribe commit' do
      it 'should not send an e-mail' do
        Subscribe.unsubscribe_from_commit @subscribe_params.merge(user_id: @user.id)
        should_not_send_email(commentor: @stranger)
      end
    end

    context 'for disabled global notify setting' do
      it 'should not send an e-mail' do
        @user.notifier.update_column :can_notify, false
        should_not_send_email(commentor: @stranger)
      end
    end
  end

  context 'for project owner user' do
    before(:each) do
      @user = FactoryGirl.create(:user)
      @stranger = FactoryGirl.create(:user)
      set_comments_data_for_commit

      @project.owner = @user
      @project.save
    end

    it_should_behave_like 'user with create comment ability (for model)'
    it_should_behave_like 'user with update own comment ability (for model)'
    it_should_behave_like 'user with update stranger comment ability (for model)'
    it_should_behave_like 'user with destroy comment ability (for model)'
    it_should_behave_like 'user with destroy stranger comment ability (for model)'

    context 'for default enabled settings' do
      it 'should send an e-mail by default settings' do
        should_send_email(commentor: @stranger, receiver: @project.owner)
      end
    end

    context 'for disabled notify setting new_comment_commit_repo_owner' do
      it 'should not send an e-mail' do
        @user.notifier.update_column :new_comment_commit_repo_owner, false
        Comment.destroy_all
        should_not_send_email(commentor: @stranger)
      end
    end

    context 'for disabled notify setting new_comment_commit_owner' do
      it 'should send an e-mail' do
        @user.notifier.update_column :new_comment_commit_owner, false
        should_send_email(commentor: @stranger, receiver: @user)
      end
    end

    context 'for disabled notify setting new_comment_commit_commentor' do
      it 'should send an e-mail' do
        @user.notifier.update_column :new_comment_commit_commentor, false
        should_send_email(commentor: @stranger, receiver: @user)
      end
    end

    context 'for disabled all notify setting expect global' do
      it 'should not send an e-mail' do
        @user.notifier.update_column :new_comment_commit_repo_owner, false
        @user.notifier.update_column :new_comment_commit_owner, false
        @user.notifier.update_column :new_comment_commit_commentor, false
        should_not_send_email(commentor: @stranger)
      end
    end

    context 'for unsubscribe project' do
      it 'should not send an e-mail' do
        Subscribe.unsubscribe_from_commit @subscribe_params.merge(user_id: @user.id)
        should_not_send_email(commentor: @stranger)
      end
    end

    context 'for disabled global notify setting' do
      it 'should not send an e-mail' do
        @user.notifier.update_column :can_notify, false
        should_not_send_email(commentor: @stranger)
      end
    end

    context 'for own commit' do
      it 'should send a one e-mail' do
        @project.owner.update_column :email, 'code@tpope.net'
        should_send_email(commentor: @stranger, receiver: @project.owner)
      end
    end
  end

  context 'for simple user' do
    before(:each) do
      @user = FactoryGirl.create(:user)
      @simple = FactoryGirl.create(:user)
      @stranger = FactoryGirl.create(:user)
      set_comments_data_for_commit
      @comment = create_comment(@simple)
      @ability = Ability.new(@simple)
      Subscribe.unsubscribe_from_commit @subscribe_params.merge(user_id: [@stranger.id, @project.owner.id])
    end

    it_should_behave_like 'user with create comment ability (for model)'
    it_should_behave_like 'user with update own comment ability (for model)'
    it_should_behave_like 'user without update stranger comment ability (for model)'
    it_should_behave_like 'user with destroy comment ability (for model)'
    it_should_behave_like 'user without destroy stranger comment ability (for model)'

    context 'for default enabled settings' do
      it 'should send an e-mail' do
        should_send_email(commentor: @stranger, receiver: @simple)
      end

      it 'should send an e-mail for comments after his comment' do
        comment = create_comment(@simple)
        should_send_email(commentor: @stranger, receiver: @simple)
      end

      it 'should send an e-mail when subscribed to project' do
        Subscribe.subscribe_to_commit @subscribe_params.merge(user_id: @simple.id)
        should_send_email(commentor: @project.owner, receiver: @simple)
      end

      it 'should not send an e-mail for own comment' do
        should_not_send_email(commentor: @simple)
      end
    end

    context 'for committer' do
      it 'should send an e-mail' do
        @simple.update_column :email, 'test@test.test'
        should_send_email commentor: @stranger, receiver: @simple
      end

      it 'should send a one e-mail when subscribed to commit' do
        Subscribe.subscribe_to_commit @subscribe_params.merge(user_id: @simple.id)
        @simple.update_column :email, 'test@test.test'
        should_send_email(commentor: @stranger, receiver: @simple)
      end

      it 'should not send an e-mail for own comment' do
        @simple.update_column :email, 'test@test.test'
        should_not_send_email(commentor: @simple)
      end

      it 'should not send an e-mail if global notify off' do
        @project.owner.notifier.update_column :can_notify, false
        @simple.update_column :email, 'test@test.test'
        @simple.notifier.update_column :can_notify, false
        should_not_send_email(commentor: @user)
      end

      it 'should not send an e-mail if notify for my commits off' do
        Comment.destroy_all
        @simple.notifier.update_column :new_comment_commit_owner, false
        @simple.update_column :email, 'test@test.test'
        should_not_send_email(commentor: @user)
      end
    end

    context 'automatic issue linking' do
      before(:each) do
        @same_name_project = FactoryGirl.create(:project, name: @project.name)
        @issue_in_same_name_project = FactoryGirl.create(:issue, project: @same_name_project, user: @same_name_project.owner)
        @another_project = FactoryGirl.create(:project, owner: @user)
        @other_user_project = FactoryGirl.create(:project)
        @issue = FactoryGirl.create(:issue, project: @project, user: @user)
        @second_issue = FactoryGirl.create(:issue, project: @project, user: @user)
        @issue_in_another_project = FactoryGirl.create(:issue, project: @another_project, user: @user)
        @issue_in_other_user_project = FactoryGirl.create(:issue, project: @other_user_project, user: @other_user_project.owner)
      end

      it 'should create automatic comment' do
        create_comment_in_commit(@commit, @project, "test link to ##{@issue.serial_id}; [##{@second_issue.serial_id}]")
        Comment.where(automatic: true, commentable_type: 'Issue',
                      commentable_id: @second_issue.id,
                      created_from_commit_hash: @commit.id.hex).count.should == 1
      end

      it 'should create automatic comment in the another project issue' do
        body = "[#{@another_project.name_with_owner}##{@issue_in_another_project.serial_id}]"
        create_comment_in_commit(@commit, @project, body)
        Comment.where(automatic: true, commentable_type: 'Issue',
                      commentable_id: @issue_in_another_project.id,
                      created_from_commit_hash: @commit.id.hex).count.should == 1
      end

      it 'should create automatic comment in the same name project issue' do
        body = "[#{@same_name_project.owner.uname}##{@issue_in_same_name_project.serial_id}]"
        create_comment_in_commit(@commit, @project, body)
        Comment.where(automatic: true, commentable_type: 'Issue',
                      commentable_id: @issue_in_same_name_project.id,
                      created_from_commit_hash: @commit.id.hex).count.should == 1
      end

      it 'should not create duplicate automatic comment' do
        create_comment_in_commit(@commit, @project, "test link to [##{@second_issue.serial_id}]")
        create_comment_in_commit(@commit, @project, "test duplicate link to [##{@second_issue.serial_id}]")
        Comment.where(automatic: true, commentable_type: 'Issue',
                      commentable_id: @second_issue.id,
                      created_from_commit_hash: @commit.id.hex).count.should == 1
      end

      it 'should not create duplicate automatic comment from one' do
        create_comment_in_commit(@commit, @project, "test link to [##{@second_issue.serial_id}]; ##{@second_issue.serial_id}")
        Comment.where(automatic: true, commentable_type: 'Issue',
                      commentable_id: @second_issue.id,
                      created_from_commit_hash: @commit.id.hex).count.should == 1
      end
      it 'should create two automatic comment' do
        body = "test ##{@second_issue.serial_id}" +
               " && [#{@another_project.name_with_owner}##{@issue_in_another_project.serial_id}]"
        create_comment_in_commit(@commit, @project, body)
        Comment.where(automatic: true,
                      created_from_commit_hash: @commit.id.hex).count.should == 2
      end
    end
  end
end
