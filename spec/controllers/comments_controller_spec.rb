# -*- encoding : utf-8 -*-
require 'spec_helper'

shared_examples_for 'user with create comment rights' do
  it 'should be able to perform create action' do
    post :create, @create_params
    response.should redirect_to(project_issue_path(@project, @issue))
  end

  it 'should create subscribe object into db' do
    lambda{ post :create, @create_params }.should change{ Comment.count }.by(1)
  end
end

shared_examples_for 'user with update own comment rights' do
  it 'should be able to perform update action' do
    put :update, {:id => @own_comment.id}.merge(@update_params)
    response.should redirect_to([@project, @issue])
  end

  it 'should update subscribe body' do
    put :update, {:id => @own_comment.id}.merge(@update_params)
    @own_comment.reload.body.should == 'updated'
  end
end

shared_examples_for 'user with update stranger comment rights' do
  it 'should be able to perform update action' do
    put :update, {:id => @comment.id}.merge(@update_params)
    response.should redirect_to([@project, @issue])
  end

  it 'should update issue title' do
    put :update, {:id => @comment.id}.merge(@update_params)
    @comment.reload.body.should == 'updated'
  end
end

shared_examples_for 'user without update stranger comment rights' do
  it 'should not be able to perform update action' do
    put :update, {:id => @comment.id}.merge(@update_params)
    response.should redirect_to(forbidden_path)
  end

  it 'should not update issue title' do
    put :update, {:id => @comment.id}.merge(@update_params)
    @comment.reload.body.should_not == 'updated'
  end
end

shared_examples_for 'user without destroy comment rights' do
  it 'should not be able to perform destroy action' do
    delete :destroy, :id => @comment.id, :issue_id => @issue.serial_id, :project_id => @project.id
    response.should redirect_to(forbidden_path)
  end

  it 'should not reduce comments count' do
    lambda{ delete :destroy, :id => @comment.id, :issue_id => @issue.serial_id, :project_id => @project.id }.should change{ Issue.count }.by(0)
  end
end

#shared_examples_for 'user with destroy rights' do
#  it 'should be able to perform destroy action' do
#    delete :destroy, :id => @comment.id, :issue_id => @issue.id, :project_id => @project.id
#    response.should redirect_to([@project, @issue])
#  end
#
#  it 'should reduce comments count' do
#    lambda{ delete :destroy, :id => @comment.id, :issue_id => @issue.id, :project_id => @project.id }.should change{ Comment.count }.by(-1)
#  end
#end

describe CommentsController do
  before(:each) do
    stub_rsync_methods

    @project = FactoryGirl.create(:project)
    @issue = FactoryGirl.create(:issue, :project_id => @project.id, :creator => FactoryGirl.create(:user))
    @comment = FactoryGirl.create(:comment, :commentable => @issue, :project_id => @project.id)

    @create_params = {:comment => {:body => 'I am a comment!'}, :project_id => @project.id, :issue_id => @issue.serial_id}
    @update_params = {:comment => {:body => 'updated'}, :project_id => @project.id, :issue_id => @issue.serial_id}

    any_instance_of(Project, :versions => ['v1.0', 'v2.0'])

    @user = FactoryGirl.create(:user)
    set_session_for(@user)
    @own_comment = FactoryGirl.create(:comment, :commentable => @issue, :user => @user, :project_id => @project.id)
  end

  context 'for project admin user' do
    before(:each) do
      @project.relations.create!(:object_type => 'User', :object_id => @user.id, :role => 'admin')
    end

    it_should_behave_like 'user with create comment rights'
    it_should_behave_like 'user with update stranger comment rights'
    it_should_behave_like 'user with update own comment rights'
    it_should_behave_like 'user without destroy comment rights'
  end

  context 'for project owner user' do
    before(:each) do
      @project.update_attribute(:owner, @user)
    end

   it_should_behave_like 'user with create comment rights'
   it_should_behave_like 'user with update stranger comment rights'
   it_should_behave_like 'user with update own comment rights'
   it_should_behave_like 'user without destroy comment rights'
  end

  context 'for project reader user' do
    before(:each) do
      @project.relations.create!(:object_type => 'User', :object_id => @user.id, :role => 'reader')
    end

   it_should_behave_like 'user with create comment rights'
   it_should_behave_like 'user without update stranger comment rights'
   it_should_behave_like 'user with update own comment rights'
   it_should_behave_like 'user without destroy comment rights'
  end

  context 'for project writer user' do
    before(:each) do
      @project.relations.create!(:object_type => 'User', :object_id => @user.id, :role => 'writer')
    end

   it_should_behave_like 'user with create comment rights'
   it_should_behave_like 'user without update stranger comment rights'
   it_should_behave_like 'user with update own comment rights'
   it_should_behave_like 'user without destroy comment rights'
  end
end
