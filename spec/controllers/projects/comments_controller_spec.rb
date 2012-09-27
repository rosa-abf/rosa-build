# -*- encoding : utf-8 -*-
require 'spec_helper'

shared_context "comments controller" do
  before(:each) do
    stub_symlink_methods

    @project = FactoryGirl.create(:project)
    @issue = FactoryGirl.create(:issue, :project_id => @project.id, :user => FactoryGirl.create(:user))
    @comment = FactoryGirl.create(:comment, :commentable => @issue, :project_id => @project.id)

    @user = FactoryGirl.create(:user)
    @own_comment = FactoryGirl.create(:comment, :commentable => @issue, :user => @user, :project_id => @project.id)

    set_session_for(@user)

    @address = {:owner_name => @project.owner.uname, :project_name => @project.name, :issue_id => @issue.serial_id}
    @create_params = {:comment => {:body => 'I am a comment!'}}.merge(@address)
    @update_params = {:comment => {:body => 'updated'}}.merge(@address)
  end

end

shared_examples_for 'user with create comment rights' do
  it 'should be able to perform create action' do
    post :create, @create_params
    response.should redirect_to(project_issue_path(@project, @issue))
  end

  it 'should create comment in the database' do
    lambda{ post :create, @create_params }.should change{ Comment.count }.by(1)
  end
end

shared_examples_for 'user with update own comment rights' do
  it 'should be able to perform update action' do
    put :update, {:id => @own_comment.id}.merge(@update_params)
    response.status.should == 200
  end

  it 'should update comment body' do
    put :update, {:id => @own_comment.id}.merge(@update_params)
    @own_comment.reload.body.should == 'updated'
  end
end

shared_examples_for 'user with update stranger comment rights' do
  it 'should be able to perform update action' do
    put :update, {:id => @comment.id}.merge(@update_params)
    response.status.should == 200
  end

  it 'should update comment body' do
    put :update, {:id => @comment.id}.merge(@update_params)
    @comment.reload.body.should == 'updated'
  end
end

shared_examples_for 'user without update stranger comment rights' do
  it 'should not be able to perform update action' do
    put :update, {:id => @comment.id}.merge(@update_params)
    response.should redirect_to(forbidden_path)
  end

  it 'should not update comment body' do
    put :update, {:id => @comment.id}.merge(@update_params)
    @comment.reload.body.should_not == 'updated'
  end
end

shared_examples_for 'user without destroy comment rights' do
  it 'should not be able to perform destroy action' do
    delete :destroy, {:id => @comment.id}.merge(@address)
    response.should redirect_to(forbidden_path)
  end

  it 'should not delete comment from database' do
    lambda{ delete :destroy, {:id => @comment.id}.merge(@address)}.should change{ Issue.count }.by(0)
  end
end

shared_examples_for 'user with destroy comment rights' do
 it 'should be able to perform destroy action' do
   delete :destroy, {:id => @comment.id}.merge(@address)
   response.should redirect_to([@project, @issue])
 end

 it 'should delete comment from database' do
   lambda{ delete :destroy, {:id => @comment.id}.merge(@address)}.should change{ Comment.count }.by(-1)
 end
end

describe Projects::CommentsController do
  include_context "comments controller"

  context 'for global admin user' do
    before(:each) do
      @user.role = "admin"
      @user.save
    end

    it_should_behave_like 'user with create comment rights'
    it_should_behave_like 'user with update stranger comment rights'
    it_should_behave_like 'user with update own comment rights'
    it_should_behave_like 'user with destroy comment rights'
  end

  context 'for project admin user' do
    before(:each) do
      @project.relations.create!(:actor_type => 'User', :actor_id => @user.id, :role => 'admin')
    end

    it_should_behave_like 'user with create comment rights'
    it_should_behave_like 'user with update stranger comment rights'
    it_should_behave_like 'user with update own comment rights'
    it_should_behave_like 'user without destroy comment rights'
  end

  context 'for project owner user' do
    before(:each) do
      set_session_for(@project.owner) # owner should be user
    end

   it_should_behave_like 'user with create comment rights'
   it_should_behave_like 'user with update stranger comment rights'
   it_should_behave_like 'user with update own comment rights'
   it_should_behave_like 'user without destroy comment rights'
  end

  context 'for project reader user' do
    before(:each) do
      @project.relations.create!(:actor_type => 'User', :actor_id => @user.id, :role => 'reader')
    end

   it_should_behave_like 'user with create comment rights'
   it_should_behave_like 'user without update stranger comment rights'
   it_should_behave_like 'user with update own comment rights'
   it_should_behave_like 'user without destroy comment rights'
  end

  context 'for project writer user' do
    before(:each) do
      @project.relations.create!(:actor_type => 'User', :actor_id => @user.id, :role => 'writer')
    end

   it_should_behave_like 'user with create comment rights'
   it_should_behave_like 'user without update stranger comment rights'
   it_should_behave_like 'user with update own comment rights'
   it_should_behave_like 'user without destroy comment rights'
  end
end
