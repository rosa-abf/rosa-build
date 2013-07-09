# -*- encoding : utf-8 -*-
shared_examples_for 'sending messages and activity feed' do
  before(:each) do
    @project_reader = FactoryGirl.create :user
    @project.relations.create!(:actor_type => 'User', :actor_id => @project_reader.id, :role => 'reader')
    @project_admin = FactoryGirl.create :user
    @project.relations.create!(:actor_type => 'User', :actor_id => @project_admin.id, :role => 'admin')
    @project_writer = FactoryGirl.create :user
    @project.relations.create!(:actor_type => 'User', :actor_id => @project_writer.id, :role => 'writer')

    set_session_for(@project_writer)
    ActionMailer::Base.deliveries = []
  end

  it 'should send two email messages to project admins' do
    post :create, @create_params
    @project.pull_requests.last.issue.send(:new_issue_notifications)
    @project.pull_requests.last.issue.send(:send_assign_notifications)
    ActionMailer::Base.deliveries.count.should == 2
  end

  it 'should send two email messages to admins and one to assignee' do
    post :create, @create_params.deep_merge(:issue => {:assignee_id => @project_reader.id})
    @project.pull_requests.last.issue.send(:new_issue_notifications)
    @project.pull_requests.last.issue.send(:send_assign_notifications)
    ActionMailer::Base.deliveries.count.should == 3
  end

  it 'should send email message to new assignee' do
    put :update, @update_params.deep_merge(:pull_request => {:assignee_id => @project_reader.id})
    @project.pull_requests.last.issue.send(:new_issue_notifications)
    @project.pull_requests.last.issue.send(:send_assign_notifications)
    ActionMailer::Base.deliveries.count.should == 1
  end
end
