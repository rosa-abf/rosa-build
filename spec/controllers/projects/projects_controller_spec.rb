require 'spec_helper'

shared_examples_for 'projects user with reader rights' do

  it 'should be able to fork project' do
    post :fork, owner_with_name: @project.name_with_owner
    response.should redirect_to(project_path(Project.last))
  end

  it 'should be able to fork project to their group' do
    group = FactoryGirl.create(:group)
    create_actor_relation(group, @user, 'admin')
    lambda { post :fork, owner_with_name: @project.name_with_owner,
             group: group.id }.should change{ Project.count }.by(1)
  end

  it 'should be able to fork project to own group' do
    group = FactoryGirl.create(:group, owner: @user)
    lambda { post :fork, owner_with_name: @project.name_with_owner,
             group: group.id }.should change{ Project.count }.by(1)
  end

  it 'should be able to fork project with different name' do
    post :fork, owner_with_name: @project.name_with_owner, fork_name: 'another_name'
    response.should redirect_to(project_path(Project.where(name: 'another_name').last))
  end
end

shared_examples_for 'projects user with project admin rights' do
  it 'should be able to perform update action' do
    put :update, { owner_with_name: @project.name_with_owner }.merge(@update_params)
    response.should redirect_to(project_path(@project))
  end
  it 'should be able to perform schedule action' do
    put :schedule, { owner_with_name: @project.name_with_owner }.merge(repository_id: @project.repositories.first.id)
    response.should be_success
  end
end

shared_examples_for 'user with destroy rights' do
  it 'should be able to perform destroy action' do
    delete :destroy, { owner_with_name: @project.name_with_owner }
    response.should redirect_to(@project.owner)
  end

  it 'should change objects count on destroy' do
    lambda { delete :destroy, owner_with_name: @project.name_with_owner }.should change{ Project.count }.by(-1)
  end
end

shared_examples_for 'projects user without project admin rights' do
  it 'should not be able to edit project' do
    description = @project.description
    put :update, project: { description:"hack" }, owner_with_name: @project.name_with_owner
    @project.reload.description.should == description
    response.should redirect_to(forbidden_path)
  end

  it 'should not be able to perform schedule action' do
    put :schedule, { owner_with_name: @project.name_with_owner }.merge(repository_id: @project.repositories.first.id)
    response.should redirect_to(forbidden_path)
  end

  it 'should not be able to edit project sections' do
    has_wiki, has_issues = @project.has_wiki, @project.has_issues
    post :sections, project: { has_wiki: !has_wiki, has_issues: !has_issues }, owner_with_name: @project.name_with_owner
    @project.reload.has_wiki.should == has_wiki
    @project.reload.has_issues.should == has_issues
    response.should redirect_to(forbidden_path)
  end

  it 'writer group should be able to fork project to their group' do
    group = FactoryGirl.create(:group)
    create_actor_relation(group, @user, 'writer')
    lambda { post :fork, owner_with_name: @project.name_with_owner,
             group: group.id }.should change{ Project.count }.by(1)
  end

  it 'reader group should not be able to fork project to their group' do
    group = FactoryGirl.create(:group)
    create_actor_relation(group, @user, 'reader')
    lambda { post :fork, owner_with_name: @project.name_with_owner,
             group: group.id }.should change{ Project.count }.by(0)
  end

  it 'writer group should be able to create project to their group' do
    group = FactoryGirl.create(:group)
    create_actor_relation(group, @user, 'wrtier')
    lambda {post :create, @create_params.merge(who_owns: 'group', owner_id: group.id)}.should change{ Project.count }.by(1)
  end

  it 'reader group should not be able to create project to their group' do
    group = FactoryGirl.create(:group)
    create_actor_relation(group, @user, 'reader')
    lambda {post :create, @create_params.merge(who_owns: 'group', owner_id: group.id)}.should change{ Project.count }.by(0)
  end
end

describe Projects::ProjectsController do

  before(:each) do
    stub_symlink_methods

    @project = FactoryGirl.create(:project)

    @create_params = {project: {name: 'pro'}}
    @update_params = {project: {description: 'pro2'}}

    @user = FactoryGirl.create(:user)
    set_session_for(@user)
  end

  context 'for users' do

    context 'guest' do

      before(:each) do
        set_session_for(User.new)
      end

      it 'should not be able to perform index action' do
        get :index
        response.should redirect_to(new_user_session_path)
      end

      it 'should not be able to perform update action' do
        put :update, { owner_with_name: @project.name_with_owner }.merge(@update_params)
        response.should redirect_to(new_user_session_path)
      end

      it 'should not be able to perform schedule action' do
        put :schedule, { owner_with_name: @project.name_with_owner }.merge(repository_id: @project.repositories.first.id)
        response.should redirect_to(new_user_session_path)
      end

      it 'should not be able to perform create action' do
        post :create, @create_params
        response.should redirect_to(new_user_session_path)
      end
    end

    context 'registered user' do

      it 'should be able to perform index action' do
        get :index
        response.should render_template(:index)
      end

      context 'create project for myself' do

        it 'should be able to perform create action' do
          post :create, @create_params
          response.should redirect_to(project_path( Project.last ))
        end

        it 'should create project in the database' do
          lambda { post :create, @create_params }.should change{ Project.count }.by(1)
        end
      end

      context 'create project for group' do

        it 'should not be able to create project for alien group' do
          group = FactoryGirl.create(:group)
          post :create, @create_params.merge({who_owns: 'group', owner_id: group.id})
          response.should redirect_to(forbidden_path)
        end

        it 'should be able to create project for their group' do
          group = FactoryGirl.create(:group)
          create_actor_relation(group, @user, 'admin')
          lambda { post :create, @create_params.merge({who_owns: 'group', owner_id: group.id})}.should change{ Project.count }.by(1)
        end

        it 'should be able to create project for own group' do
          group = FactoryGirl.create(:group, owner: @user)
          lambda { post :create, @create_params.merge({who_owns: 'group', owner_id: group.id})}.should change{ Project.count }.by(1)
        end
      end

    end # context 'registered user'
  end # context 'for users'

  context 'for project members' do

    context 'for global admin' do
      before(:each) do
        @user.role = "admin"
        @user.save
        set_session_for(@user)
      end

      it_should_behave_like 'projects user with project admin rights'
      it_should_behave_like 'projects user with reader rights'
      it_should_behave_like 'user with destroy rights'

    end

    context 'for owner user' do
      before(:each) do
        @user = @project.owner
        set_session_for(@user) # owner should be user
      end

      it_should_behave_like 'projects user with project admin rights'
      it_should_behave_like 'projects user with reader rights'
      it_should_behave_like 'user with destroy rights'

      it 'should not be able to fork own project' do
        post :fork, owner_with_name: @project.name_with_owner
        response.should redirect_to(@project)
      end

    end

    context 'for reader user' do
      before(:each) do
        create_relation(@project, @user, 'reader')
      end

      it_should_behave_like 'projects user with reader rights'
      it_should_behave_like 'projects user without project admin rights'
    end

    context 'for writer user' do
      before(:each) do
        create_relation(@project, @user, 'writer')
      end

      it_should_behave_like 'projects user with reader rights'
      it_should_behave_like 'projects user without project admin rights'

    end

    context 'for other user' do

      it 'should not be able to fork hidden project' do
        @project.update_attributes(visibility: 'hidden')
        post :fork, owner_with_name: @project.name_with_owner
        response.should redirect_to(forbidden_path)
      end

      it_should_behave_like 'projects user without project admin rights'

    end

  end # context 'for project members'

  context 'for group' do
    before(:each) do
      @group = FactoryGirl.create(:group)
    end

    context 'group is owner of the project' do
      before(:each) do
        @project = FactoryGirl.create(:project, owner: @group)
      end

      context 'group member user with reader role' do
        before(:each) { create_actor_relation(@group, @user, 'reader') }

        it_should_behave_like 'projects user with reader rights'
        it_should_behave_like 'projects user without project admin rights'

        it 'should has reader role to group project' do
          @user.best_role(@project).should eql('reader')
        end

        context 'user should has best role' do
          before(:each) { create_relation(@project, @user, 'admin') }
          it_should_behave_like 'projects user with project admin rights'
        end
      end

      context 'group member user with admin role' do
        before(:each) { create_actor_relation(@group, @user, 'admin') }

        it_should_behave_like 'projects user with project admin rights'
        it_should_behave_like 'projects user with reader rights'
      end
    end

    context 'group is member of the project' do
      context 'with admin rights' do
        before(:each) { create_relation(@project, @group, 'admin') }

        context 'group member user with reader role' do
          before(:each) { create_actor_relation(@group, @user, 'reader') }

          it_should_behave_like 'projects user with reader rights'
          it_should_behave_like 'projects user with project admin rights'

          context 'user should has best role' do
            before(:each) { create_relation(@project, @user, 'reader') }
            it_should_behave_like 'projects user with project admin rights'
          end
        end

        context 'group member user with admin role' do
          before(:each) { create_actor_relation(@group, @user, 'admin') }

          it_should_behave_like 'projects user with project admin rights'
          it_should_behave_like 'projects user with reader rights'
        end
      end

      context 'with reader rights' do
        before(:each) { create_relation(@project, @group, 'reader') }

        context 'group member user with reader role' do
          before(:each) { create_actor_relation(@group, @user, 'reader') }

          it_should_behave_like 'projects user with reader rights'
          it_should_behave_like 'projects user without project admin rights'

          context 'user should has best role' do
            before(:each) { create_relation(@project, @user, 'admin') }
            it_should_behave_like 'projects user with project admin rights'
          end
        end

        context 'group member user with admin role' do
          before(:each) { create_actor_relation(@group, @user, 'admin') }

          it_should_behave_like 'projects user with reader rights'
          it_should_behave_like 'projects user without project admin rights'
        end
      end
    end
  end
end
