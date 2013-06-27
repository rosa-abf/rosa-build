# -*- encoding : utf-8 -*-
require 'spec_helper'

describe Modules::Observers::ActivityFeed::Issue do
  before { stub_symlink_methods }

  it 'sends a notification email after create' do
    issue = FactoryGirl.build(:issue, :assignee => nil)
    mailer = mock!.deliver
    mock(UserMailer).new_issue_notification(issue, issue.project.owner) { mailer }
    issue.save
  end

  it 'does not send a notification email after update' do
    issue = FactoryGirl.create(:issue, :assignee => nil)
    issue.title = 'new title'
    dont_allow(UserMailer).new_issue_notification
    issue.save
  end

  it 'sends a notification email after a assignee of issue has been changed' do
    user = FactoryGirl.create(:user)
    issue = FactoryGirl.build(:issue, :assignee => nil)
    issue.assignee = user
    mailer = mock!.deliver
    mock(UserMailer).issue_assign_notification(issue, user) { mailer }
    issue.save
  end

end
