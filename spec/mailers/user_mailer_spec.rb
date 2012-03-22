# -*- encoding : utf-8 -*-
require "spec_helper"

describe UserMailer do
  pending "add some examples to (or delete) #{__FILE__}"

  context 'On Issue create' do
    before(:each) do
      stub_rsync_methods

      @project = Factory(:project)
      @issue_user = Factory(:user)

      any_instance_of(Project, :versions => ['v1.0', 'v2.0'])

      @issue = Factory(:issue, :project_id => @project.id, :user_id => @issue_user.id, :creator => @issue_user)
      @email = UserMailer.new_issue_notification(@issue, @issue_user).deliver
    end

    it 'should have correct subject' do
      @email.subject.should == I18n.t("notifications.subjects.new_issue_notification")
    end

    it 'should render receiver email' do
      @email.to.should == [@issue_user.email]
    end

    it 'should render the sender email' do
      @email.from.should == [APP_CONFIG['do-not-reply-email']]
    end

    it 'should assign user name' do
      @email.body.encoded.should match(@issue_user.name)
    end

    it 'should assign issue project name' do
      @email.body.encoded.should match(@issue.project.name)
    end

    it 'should assign issue title' do
      @email.body.encoded.should match(@issue.title)
    end
  end

  context 'On Issue assign' do
    before(:each) do
      stub_rsync_methods

      @project = Factory(:project)
      @issue_user = Factory(:user)
      @user = Factory(:user)

      any_instance_of(Project, :versions => ['v1.0', 'v2.0'])

      @issue = Factory(:issue, :project_id => @project.id, :user_id => @issue_user.id, :creator => @issue_user)
      @email = UserMailer.issue_assign_notification(@issue, @user).deliver
    end

    it 'should have correct subject' do
      @email.subject.should == I18n.t("notifications.subjects.issue_assign_notification")
    end

    it 'should render receiver email' do
      @email.to.should == [@user.email]
    end

    it 'should render the sender email' do
      @email.from.should == [APP_CONFIG['do-not-reply-email']]
    end

    it 'should assign user name' do
      @email.body.encoded.should match(@user.name)
    end

    it 'should assign issue title' do
      @email.body.encoded.should match(@issue.title)
    end
  end


  context 'On Comment create' do
    before(:each) do
      stub_rsync_methods

      @project = Factory(:project)
      @issue_user = Factory(:user)
      @user = Factory(:user)

      any_instance_of(Project, :versions => ['v1.0', 'v2.0'])

      @issue = Factory(:issue, :project_id => @project.id, :user_id => @issue_user.id, :creator => @issue_user)
      @comment = Factory(:comment, :commentable => @issue, :user_id => @user.id, :project => @project)
      @email = UserMailer.new_comment_notification(@comment, @issue_user).deliver
    end

    it 'should have correct subject' do
      @email.subject.should == I18n.t("notifications.subjects.new_comment_notification")
    end

    it 'should render receiver email' do
      @email.to.should == [@issue_user.email]
    end

    it 'should render the sender email' do
      @email.from.should == [APP_CONFIG['do-not-reply-email']]
    end

    it 'should assign user name' do
      @email.body.encoded.should match(@issue_user.name)
    end

    it 'should assign comment body' do
      @email.body.encoded.should match(@comment.body)
    end

    it 'should assign issue title' do
      @email.body.encoded.should match(@issue.title)
    end
  end
end
