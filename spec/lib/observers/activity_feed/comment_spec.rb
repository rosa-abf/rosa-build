# -*- encoding : utf-8 -*-
require 'spec_helper'

describe Modules::Observers::ActivityFeed::Comment do
  before { stub_symlink_methods }
  
  it 'sends a notification email after create a issue comment' do
    comment = FactoryGirl.build(:comment)
    mailer = mock!.deliver
    mock(UserMailer).new_comment_notification(comment, comment.commentable.assignee) { mailer }
    comment.save
  end

end
