require 'spec_helper'

shared_context "comments controller" do
  before(:each) do
    stub_symlink_methods

    @project = FactoryGirl.create(:project)
    @issue = FactoryGirl.create(:issue, project_id: @project.id)
    @comment = FactoryGirl.create(:comment, commentable: @issue, project_id: @project.id)

    @user = FactoryGirl.create(:user)
    @own_comment = FactoryGirl.create(:comment, commentable: @issue, user: @user, project_id: @project.id)

    set_session_for(@user)

    @path = { name_with_owner: @project.name_with_owner, issue_id: @issue.serial_id, format: :json }
    @return_path = project_issue_path(@project, @issue)
    @create_params = { comment: { body: 'I am a comment!' }}.merge(@path)
    @update_params = { comment: { body: 'updated' }}.merge(@path)
  end

end

describe Projects::CommentsController, type: :controller do
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
      create_relation(@project, @user, 'admin')
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
      create_relation(@project, @user, 'reader')
    end

   it_should_behave_like 'user with create comment ability'
   it_should_behave_like 'user without update stranger comment ability'
   it_should_behave_like 'user with update own comment ability'
   it_should_behave_like 'user without destroy comment ability'
  end

  context 'for project writer user' do
    before(:each) do
      create_relation(@project, @user, 'writer')
    end

   it_should_behave_like 'user with create comment ability'
   it_should_behave_like 'user without update stranger comment ability'
   it_should_behave_like 'user with update own comment ability'
   it_should_behave_like 'user without destroy comment ability'
  end
end
