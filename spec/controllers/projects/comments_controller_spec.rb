require 'spec_helper'

shared_context "comments controller" do
  before(:each) do
    stub_symlink_methods

    @project = FactoryGirl.create(:project)
    @issue = FactoryGirl.create(:issue, :project_id => @project.id)
    @comment = FactoryGirl.create(:comment, :commentable => @issue, :project_id => @project.id)

    @user = FactoryGirl.create(:user)
    @own_comment = FactoryGirl.create(:comment, :commentable => @issue, :user => @user, :project_id => @project.id)

    set_session_for(@user)

    @path = {:owner_name => @project.owner.uname, :project_name => @project.name, :issue_id => @issue.serial_id}
    @return_path = project_issue_path(@project, @issue)
    @create_params = {:comment => {:body => 'I am a comment!'}}.merge(@path)
    @update_params = {:comment => {:body => 'updated'}}.merge(@path)
  end

end

describe Projects::CommentsController do
  include_context "comments controller"

  context 'for global admin user' do
    before(:each) do
      @user.role = "admin"
      @user.save
    end

    it_should_behave_like 'user with create comment ability'
    it_should_behave_like 'user with update stranger comment ability'
    it_should_behave_like 'user with update own comment ability'
    it_should_behave_like 'user with destroy comment ability'
  end

  context 'for project admin user' do
    before(:each) do
      @project.relations.create!(:actor_type => 'User', :actor_id => @user.id, :role => 'admin')
    end

    it_should_behave_like 'user with create comment ability'
    it_should_behave_like 'user with update stranger comment ability'
    it_should_behave_like 'user with update own comment ability'
    it_should_behave_like 'user with destroy comment ability'
  end

  context 'for project owner user' do
    before(:each) do
      set_session_for(@project.owner) # owner should be user
    end

   it_should_behave_like 'user with create comment ability'
   it_should_behave_like 'user with update stranger comment ability'
   it_should_behave_like 'user with update own comment ability'
   it_should_behave_like 'user with destroy comment ability'
  end

  context 'for project reader user' do
    before(:each) do
      @project.relations.create!(:actor_type => 'User', :actor_id => @user.id, :role => 'reader')
    end

   it_should_behave_like 'user with create comment ability'
   it_should_behave_like 'user without update stranger comment ability'
   it_should_behave_like 'user with update own comment ability'
   it_should_behave_like 'user without destroy comment ability'
  end

  context 'for project writer user' do
    before(:each) do
      @project.relations.create!(:actor_type => 'User', :actor_id => @user.id, :role => 'writer')
    end

   it_should_behave_like 'user with create comment ability'
   it_should_behave_like 'user without update stranger comment ability'
   it_should_behave_like 'user with update own comment ability'
   it_should_behave_like 'user without destroy comment ability'
  end
end
