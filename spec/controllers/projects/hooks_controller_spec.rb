require 'spec_helper'

shared_examples_for 'hooks user with project admin rights' do
  it 'should be able to perform index action' do
    get :index, {owner_name: @project.owner.uname, project_name: @project.name}
    response.should be_success
  end

  it 'should be able to perform new action' do
    get :new, {owner_name: @project.owner.uname, project_name: @project.name, hook: {name: 'web'}}
    response.should be_success
  end

  it 'should be able to perform edit action' do
    get :new, {owner_name: @project.owner.uname, project_name: @project.name, id: @hook.id}
    response.should be_success
  end

  it 'should be able to perform update action' do
    put :update, {owner_name: @project.owner.uname, project_name: @project.name, id: @hook.id}.merge(@update_params)
    response.should redirect_to(project_hooks_path(@project, name: 'web'))
  end

  it 'should be able to perform create action' do
    post :create, {owner_name: @project.owner.uname, project_name: @project.name}.merge(@create_params)
    response.should redirect_to(project_hooks_path(@project, name: 'web'))
  end
end

shared_examples_for 'hooks user without project admin rights' do
  it 'should not be able to perform index action' do
    get :index, {owner_name: @project.owner.uname, project_name: @project.name}
    response.should redirect_to(forbidden_path)
  end

  it 'should not be able to perform new action' do
    get :new, {owner_name: @project.owner.uname, project_name: @project.name, hook: {name: 'web'}}
    response.should redirect_to(forbidden_path)
  end

  it 'should not be able to perform edit action' do
    get :new, {owner_name: @project.owner.uname, project_name: @project.name, id: @hook.id}
    response.should redirect_to(forbidden_path)
  end

  it 'should not be able to perform update action' do
    put :update, {owner_name: @project.owner.uname, project_name: @project.name, id: @hook.id}.merge(@update_params)
    response.should redirect_to(forbidden_path)
  end

  it 'should not be able to perform create action' do
    post :create, {owner_name: @project.owner.uname, project_name: @project.name}.merge(@create_params)
    response.should redirect_to(forbidden_path)
  end
end

describe Projects::HooksController do

  before(:each) do
    stub_symlink_methods

    @project = FactoryGirl.create(:project)
    @hook = FactoryGirl.create(:hook, project: @project)

    @create_params = {hook: {name: 'web', data: {url: 'create'}}}
    @update_params = {hook: {data: {url: 'update'}}}

    @user = FactoryGirl.create(:user)
    set_session_for(@user)
  end

  context 'registered user' do
    it_should_behave_like 'hooks user without project admin rights'
  end # context 'registered user'

  context 'for project members' do

    context 'for global admin' do
      before do
        @user.role = "admin"
        @user.save
      end

      it_should_behave_like 'hooks user with project admin rights'
    end

    context 'for owner user' do
      before do
        @user = @project.owner
        set_session_for(@user) # owner should be user
      end
      it_should_behave_like 'hooks user with project admin rights'
    end

    context 'for reader user' do
      before do
        create_relation(@project, @user, 'reader')
      end
      it_should_behave_like 'hooks user without project admin rights'
    end

    context 'for writer user' do
      before do
        create_relation(@project, @user, 'writer')
      end
      it_should_behave_like 'hooks user without project admin rights'
    end

  end # context 'for project members'

  context 'for group' do
    before do
      @group = FactoryGirl.create(:group)
    end

    context 'group is owner of the project' do
      before do
        @project = FactoryGirl.create(:project, owner: @group)
        @hook = FactoryGirl.create(:hook, project: @project)
      end

      context 'group member user with reader role' do
        before { create_actor_relation(@group, @auser, 'reader') }

        it_should_behave_like 'hooks user without project admin rights'

        context 'user should has best role' do
          before { create_relation(@project, @user, 'admin') }
          it_should_behave_like 'hooks user with project admin rights'
        end
      end

      context 'group member user with admin role' do
        before { create_actor_relation(@group, @user, 'admin') }
        it_should_behave_like 'hooks user with project admin rights'
      end
    end

    context 'group is member of the project' do
      context 'with admin rights' do
        before { create_relation(@project, @group, 'admin') }

        context 'group member user with reader role' do
          before { create_actor_relation(@group, @user, 'reader') }

          it_should_behave_like 'hooks user with project admin rights'

          context 'user should has best role' do
            before { create_relation(@project, @user, 'reader') }
            it_should_behave_like 'hooks user with project admin rights'
          end
        end

        context 'group member user with admin role' do
          before { create_actor_relation(@group, @user, 'admin') }
          it_should_behave_like 'hooks user with project admin rights'
        end
      end

      context 'with reader rights' do
        before { create_relation(@project, @group, 'reader') }

        context 'group member user with reader role' do
          before { create_actor_relation(@group, @user, 'reader') }

          it_should_behave_like 'hooks user without project admin rights'

          context 'user should has best role' do
            before { create_relation(@project, @user, 'admin') }
            it_should_behave_like 'hooks user with project admin rights'
          end
        end

        context 'group member user with admin role' do
          before { create_actor_relation(@group, @user, 'admin') }
          it_should_behave_like 'hooks user without project admin rights'
        end
      end
    end
  end
end
