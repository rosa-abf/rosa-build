require 'spec_helper'

shared_context "collaborators controller" do
  before(:each) do
    stub_symlink_methods
    @project = FactoryGirl.create(:project)
    @another_user = FactoryGirl.create(:user)
    @group = FactoryGirl.create(:group)
    @member_user = FactoryGirl.create(:user)
    # Create relation with 'writer' rights
    @collaborator = Collaborator.create(actor: @member_user, project: @project, role: 'writer')

    @user = FactoryGirl.create(:user)
    set_session_for(@user)

    @user_params = {
        actor_id: @another_user.id.to_s,
        actor_type: 'user',
        role: 'reader'
    }
    @group_params = {
        actor_id: @group.id.to_s,
        actor_type: 'group',
        role: 'reader'
    } if @group
    @create_params = {
      owner_name: @project.owner.uname, project_name: @project.name,
      format: :json
    }
    @update_params = @create_params.merge(collaborator: {role: 'reader'})
  end
end

shared_examples_for 'project admin user' do
  it 'should be able to view collaborators list' do
    get :index, owner_name: @project.owner.uname, project_name: @project.name
    response.should be_success
  end

  it 'should be able to perform update action' do
    put :update, {id: @collaborator.id}.merge(@update_params)
    response.should be_success
  end

  it 'should add new collaborator with reader role' do
    post :create, @create_params.merge(collaborator: @user_params)
    @project.relations.exists?(actor_type: 'User', actor_id: @another_user.id, role: 'reader').should be_true
  end

  it 'should add new group with reader role' do
    post :create, @create_params.merge(collaborator: @group_params)
    @project.relations.exists?(actor_type: 'Group', actor_id: @group.id, role: 'reader').should be_true
  end

  it 'should be able to set reader role for any user' do
    put :update, {id: @collaborator.id}.merge(@update_params)
    @another_user.relations.exists? target_id: @project.id, target_type: 'Project', role: 'read'
  end
end

shared_examples_for 'user with no rights for this project' do
  it 'should not be able to view collaborators list' do
    get :index, owner_name: @project.owner.uname, project_name: @project.name
    response.should redirect_to(forbidden_path)
  end

  it 'should not be able to perform update action' do
    put :update, {id: @collaborator.id}.merge(@update_params)
    response.should redirect_to(forbidden_path)
  end

  it 'should not be able to set reader role for any user' do
    put :update, {id: @collaborator.id}.merge(@update_params)
    !@another_user.relations.exists? target_id: @project.id, target_type: 'Project', role: 'read'
  end
end

describe Projects::CollaboratorsController do
  include_context "collaborators controller"

  context 'for guest' do
    before(:each) do
      set_session_for(User.new)
    end
    it 'should not be able to perform index action' do
      get :index, owner_name: @project.owner.uname, project_name: @project.name
      response.should redirect_to(new_user_session_path)
    end

    it 'should not be able to perform update action' do
      put :update, {id: @collaborator.id}.merge(@update_params)
      response.code.should == '401'
    end
  end

  context 'for global admin' do
    before(:each) do
      @user.role = "admin"
      @user.save
    end

    it_should_behave_like 'project admin user'
  end

  context 'for admin user' do
    before(:each) do
      create_relation(@project, @user, 'admin')
    end

    it_should_behave_like 'project admin user'
  end

  context 'for owner user' do
    before(:each) do
      @user = @project.owner # owner should be user
      set_session_for(@user)
    end

    it_should_behave_like 'project admin user'
  end

  context 'for reader user' do
    before(:each) do
      create_relation(@project, @user, 'reader')
    end

    it_should_behave_like 'user with no rights for this project'
  end

  context 'for writer user' do
    before(:each) do
      create_relation(@project, @user, 'writer')
    end

    it_should_behave_like 'user with no rights for this project'
  end
end
