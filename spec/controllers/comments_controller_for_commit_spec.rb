# -*- encoding : utf-8 -*-
require 'spec_helper'

shared_examples_for 'user with create comment rights for commits' do
  it 'should be able to perform create action' do
    post :create, @create_params
    response.should redirect_to(commit_path(@project, @commit.id))
  end

  it 'should create subscribe object into db' do
    lambda{ post :create, @create_params }.should change{ Comment.count }.by(1)
  end
end

shared_examples_for 'user with update own comment rights for commits' do
  it 'should be able to perform update action' do
    put :update, {:id => @own_comment.id}.merge(@update_params)
    response.should redirect_to(commit_path(@project, @commit.id))
  end

  it 'should update subscribe body' do
    put :update, {:id => @own_comment.id}.merge(@update_params)
    @own_comment.reload.body.should == 'updated'
  end
end

shared_examples_for 'user with update stranger comment rights for commits' do
  it 'should be able to perform update action' do
    put :update, {:id => @comment.id}.merge(@update_params)
    response.should redirect_to(commit_path(@project, @commit.id))
  end

  it 'should update comment title' do
    put :update, {:id => @comment.id}.merge(@update_params)
    @comment.reload.body.should == 'updated'
  end
end

shared_examples_for 'user without update stranger comment rights for commits' do
  it 'should not be able to perform update action' do
    put :update, {:id => @comment.id}.merge(@update_params)
    response.should redirect_to(forbidden_path)
  end

  it 'should not update comment title' do
    put :update, {:id => @comment.id}.merge(@update_params)
    @comment.reload.body.should_not == 'updated'
  end
end

shared_examples_for 'user without destroy comment rights for commits' do
  it 'should not be able to perform destroy action' do
    delete :destroy, :id => @comment.id, :commit_id => @commit.id, :project_id => @project.id
    response.should redirect_to(forbidden_path)
  end

  it 'should not reduce comments count' do
    lambda{ delete :destroy, :id => @comment.id, :commit_id => @commit.id, :project_id => @project.id }.should change{ Comment.count }.by(0)
  end
end

#shared_examples_for 'user with destroy rights' do
#  it 'should be able to perform destroy action' do
#    delete :destroy, :id => @comment.id, :issue_id => @issue.serial_id, :project_id => @project.id
#    response.should redirect_to([@project, @issue])
#  end
#
#  it 'should reduce comments count' do
#    lambda{ delete :destroy, :id => @comment.id, :issue_id => @issue.serial_id, :project_id => @project.id }.should change{ Comment.count }.by(-1)
#  end
#end

describe CommentsController do
  before(:each) do
    stub_rsync_methods

    @project = Factory(:project)
    %x(cp -Rf #{Rails.root}/spec/tests.git/* #{@project.git_repository.path}) # maybe FIXME ?
    @commit = @project.git_repository.commits.first

    @comment = Factory(:comment)
    @comment.update_attributes(:commentable_type => @commit.class.name, :commentable_id => @commit.id)
    @create_params = {:comment => {:body => 'I am a comment!'}, :project_id => @project.id, :commit_id => @commit.id}
    @update_params = {:comment => {:body => 'updated'}, :project_id => @project.id, :commit_id => @commit.id}

    any_instance_of(Project, :versions => ['v1.0', 'v2.0'])

    @request.env['HTTP_REFERER'] = commit_path(@project, @commit.id)
  end

  context 'for project admin user' do
    before(:each) do
      @user = Factory(:user)
      set_session_for(@user)
      @project.relations.create!(:object_type => 'User', :object_id => @user.id, :role => 'admin')
      @own_comment = Factory(:comment, :user => @user)
      @own_comment.update_attributes(:commentable_type => @commit.class.name, :commentable_id => @commit.id)
    end

    it_should_behave_like 'user with create comment rights for commits'
    it_should_behave_like 'user with update stranger comment rights for commits'
    it_should_behave_like 'user with update own comment rights for commits'
    it_should_behave_like 'user without destroy comment rights for commits'
  end

  context 'for project owner user' do
    before(:each) do
      @user = @project.owner
      set_session_for(@user)
      @project.relations.create!(:object_type => 'User', :object_id => @user.id, :role => 'admin')

      @own_comment = Factory(:comment, :user => @user)
      @own_comment.update_attributes(:commentable_type => @commit.class.name, :commentable_id => @commit.id)
    end

   it_should_behave_like 'user with create comment rights for commits'
   it_should_behave_like 'user with update stranger comment rights for commits'
   it_should_behave_like 'user with update own comment rights for commits'
   it_should_behave_like 'user without destroy comment rights for commits'
  end

  context 'for project reader user' do
    before(:each) do
      @user = Factory(:user)
      set_session_for(@user)
      @project.relations.create!(:object_type => 'User', :object_id => @user.id, :role => 'reader')

      @own_comment = Factory(:comment, :user => @user)
      @own_comment.update_attributes(:commentable_type => @commit.class.name, :commentable_id => @commit.id)
    end

   it_should_behave_like 'user with create comment rights for commits'
   it_should_behave_like 'user without update stranger comment rights for commits'
   it_should_behave_like 'user with update own comment rights for commits'
   it_should_behave_like 'user without destroy comment rights for commits'
  end

  context 'for project writer user' do
    before(:each) do
      @user = Factory(:user)
      set_session_for(@user)
      @project.relations.create!(:object_type => 'User', :object_id => @user.id, :role => 'writer')

      @own_comment = Factory(:comment, :user => @user)
      @own_comment.update_attributes(:commentable_type => @commit.class.name, :commentable_id => @commit.id)
    end

   it_should_behave_like 'user with create comment rights for commits'
   it_should_behave_like 'user without update stranger comment rights for commits'
   it_should_behave_like 'user with update own comment rights for commits'
   it_should_behave_like 'user without destroy comment rights for commits'
  end
end
