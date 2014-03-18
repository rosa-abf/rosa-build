require 'spec_helper'

describe Projects::CommentsController do
  before(:each) do
    stub_symlink_methods
    @project = FactoryGirl.create(:project_with_commit)
    @commit = @project.repo.commits.first

    @create_params = {comment: {body: 'I am a comment!'}, owner_with_name: "#{@project.owner.uname}/#{@project.name}", commit_id: @commit.id}
    @update_params = {comment: {body: 'updated'}, owner_with_name: "#{@project.owner.uname}/#{@project.name}", commit_id: @commit.id}

    any_instance_of(Project, versions: ['v1.0', 'v2.0'])
    @comment = FactoryGirl.create(:comment, commentable: @commit, project: @project)
    @user = FactoryGirl.create(:user)
    @own_comment = FactoryGirl.create(:comment, commentable: @commit, user: @user, project: @project)
    set_session_for(@user)
    @path = {owner_with_name: "#{@project.owner.uname}/#{@project.name}", commit_id: @commit.id}
    @return_path = commit_path(@project, @commit.id)
  end

  context 'for project admin user' do
    before(:each) do
      create_relation(@project, @user, 'admin')
    end

    it_should_behave_like 'user with create comment ability'
    it_should_behave_like 'user with update stranger comment ability'
    it_should_behave_like 'user with update own comment ability'
    it_should_behave_like 'user with destroy comment ability'
    #it_should_behave_like 'user with destroy ability'
  end

  context 'for project owner user' do
    before(:each) do
      set_session_for(@project.owner)
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
