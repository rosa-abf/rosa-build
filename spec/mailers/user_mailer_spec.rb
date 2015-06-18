require "spec_helper"

describe UserMailer do

  context 'On Issue create' do
    let(:project)    { FactoryGirl.build(:project) }
    let(:issue_user) { FactoryGirl.build(:user) }
    let(:issue)      { FactoryGirl.build(:issue, project: project, assignee: issue_user, user: issue_user) }
    let(:email)      { UserMailer.new_issue_notification(issue.id, issue_user.id).deliver! }

    before do
      stub_symlink_methods

      allow(User).to receive(:find) { issue_user }
      allow(Issue).to receive(:find) { issue }
    end

    it 'should have correct subject' do
      expect(email.subject).to eq "[#{issue.project.name}] #{issue.title} (##{issue.serial_id})"
    end

    it 'should render receiver email' do
      expect(email.to).to eq [issue_user.email]
    end

    it 'should render the sender email' do
      expect(email.from).to eq [APP_CONFIG['do-not-reply-email']]
    end

    it 'should assign issue project name' do
      expect(email.body.encoded).to match(issue.project.name)
    end

    it 'should assign issue body' do
      expect(email.body.encoded).to match(issue.body)
    end
  end

  context 'On Issue assign' do
    let(:project)    { FactoryGirl.build(:project) }
    let(:issue_user) { FactoryGirl.build(:user) }
    let(:user)       { FactoryGirl.build(:user) }
    let(:issue)      { FactoryGirl.build(:issue, project: project, assignee: issue_user, user: issue_user) }
    let(:email)      { UserMailer.issue_assign_notification(issue, user).deliver! }

    before do
      stub_symlink_methods
    end

    it 'should have correct subject' do
      expect(email.subject).to eq "Re: [#{issue.project.name}] #{issue.title} (##{issue.serial_id})"
    end

    it 'should render receiver email' do
      expect(email.to).to eq [user.email]
    end

    it 'should render the sender email' do
      expect(email.from).to eq [APP_CONFIG['do-not-reply-email']]
    end

    it 'should assign issue title' do
      expect(email.body.encoded).to match(issue.title)
    end
  end

  context 'On Comment create' do
    let(:project)    { FactoryGirl.build(:project) }
    let(:issue_user) { FactoryGirl.build(:user) }
    let(:user)       { FactoryGirl.build(:user) }
    let(:issue)      { FactoryGirl.build(:issue, project: project, assignee: issue_user, user: issue_user) }
    let(:comment)    { FactoryGirl.build(:comment, commentable: issue, user: user, project: project) }
    let(:email)      { UserMailer.new_comment_notification(comment, issue_user.id).deliver! }

    before do
      stub_symlink_methods

      allow(User).to receive(:find) { issue_user }
    end

    it 'should have correct subject' do
      expect(email.subject).to eq "Re: [#{issue.project.name}] #{issue.title} (##{issue.serial_id})"
    end

    it 'should render receiver email' do
      expect(email.to).to eq [issue_user.email]
    end

    it 'should render the sender email' do
      expect(email.from).to eq [APP_CONFIG['do-not-reply-email']]
    end

    it 'should assign comment body' do
      expect(email.body.encoded).to match(comment.body)
    end
  end
end
