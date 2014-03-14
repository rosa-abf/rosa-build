require "spec_helper"

describe UserMailer do

  context 'On Issue create' do
    before do
      stub_symlink_methods

      @project = FactoryGirl.create(:project)
      @issue_user = FactoryGirl.create(:user)

      any_instance_of(Project, versions: ['v1.0', 'v2.0'])

      @issue = FactoryGirl.create(:issue, project: @project, assignee: @issue_user, user: @issue_user)
      @email = UserMailer.new_issue_notification(@issue, @issue_user).deliver!
    end

    it 'should have correct subject' do
      @email.subject.should == "[#{@issue.project.name}] #{@issue.title} (##{@issue.serial_id})"
    end

    it 'should render receiver email' do
      @email.to.should == [@issue_user.email]
    end

    it 'should render the sender email' do
      @email.from.should == [APP_CONFIG['do-not-reply-email']]
    end

    it 'should assign issue project name' do
      @email.body.encoded.should match(@issue.project.name)
    end

    it 'should assign issue body' do
      @email.body.encoded.should match(@issue.body)
    end
  end

  context 'On Issue assign' do
    before(:each) do
      stub_symlink_methods

      @project = FactoryGirl.create(:project)
      @issue_user = FactoryGirl.create(:user)
      @user = FactoryGirl.create(:user)

      any_instance_of(Project, versions: ['v1.0', 'v2.0'])

      @issue = FactoryGirl.create(:issue, project_id: @project.id, assignee_id: @issue_user.id, user: @issue_user)
      @email = UserMailer.issue_assign_notification(@issue, @user).deliver!
    end

    it 'should have correct subject' do
      @email.subject.should == "Re: [#{@issue.project.name}] #{@issue.title} (##{@issue.serial_id})"
    end

    it 'should render receiver email' do
      @email.to.should == [@user.email]
    end

    it 'should render the sender email' do
      @email.from.should == [APP_CONFIG['do-not-reply-email']]
    end

    it 'should assign issue title' do
      @email.body.encoded.should match(@issue.title)
    end
  end


  context 'On Comment create' do
    before do
      stub_symlink_methods

      @project = FactoryGirl.create(:project)
      @issue_user = FactoryGirl.create(:user)
      @user = FactoryGirl.create(:user)

      any_instance_of(Project, versions: ['v1.0', 'v2.0'])

      @issue = FactoryGirl.create(:issue, project: @project, assignee: @issue_user, user: @issue_user)
      @comment = FactoryGirl.create(:comment, commentable: @issue, user: @user, project: @project)
      @email = UserMailer.new_comment_notification(@comment, @issue_user).deliver!
    end

    it 'should have correct subject' do
      @email.subject.should == "Re: [#{@issue.project.name}] #{@issue.title} (##{@issue.serial_id})"
    end

    it 'should render receiver email' do
      @email.to.should == [@issue_user.email]
    end

    it 'should render the sender email' do
      @email.from.should == [APP_CONFIG['do-not-reply-email']]
    end

    it 'should assign comment body' do
      @email.body.encoded.should match(@comment.body)
    end
  end
end
