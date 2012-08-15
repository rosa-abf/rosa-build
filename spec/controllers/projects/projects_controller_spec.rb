# -*- encoding : utf-8 -*-
require 'spec_helper'

describe Projects::ProjectsController do

  before(:each) do
    stub_symlink_methods

    @project = FactoryGirl.create(:project)
    @another_user = FactoryGirl.create(:user)
    @create_params = {:project => {:name => 'pro'}}
    @update_params = {:project => {:description => 'pro2'}}
  end

  context 'for guest' do
    it 'should not be able to perform index action' do
      get :index
      response.should redirect_to(new_user_session_path)
    end

    it 'should not be able to perform update action' do
      put :update, {:owner_name => @project.owner.uname, :project_name => @project.name}.merge(@update_params)
      response.should redirect_to(new_user_session_path)
    end
  end

  context 'for admin' do
    before(:each) do
      @admin = FactoryGirl.create(:admin)
      set_session_for(@admin)
    end

    it_should_behave_like 'projects user with admin rights'
    it_should_behave_like 'projects user with reader rights'

    it 'should be able to perform create action' do
      post :create, @create_params
      response.should redirect_to(project_path( Project.last ))
    end

    it 'should change objects count on create' do
      lambda { post :create, @create_params }.should change{ Project.count }.by(1)
    end
  end

  context 'for owner user' do
    before(:each) do
      @user = FactoryGirl.create(:user)
      set_session_for(@user)
      @project.owner = @user; @project.save!; @project.reload
      @project.relations.create!(:actor_type => 'User', :actor_id => @user.id, :role => 'admin')
    end

    it_should_behave_like 'projects user with admin rights'
    it_should_behave_like 'user with rights to view projects'

    it 'should be able to perform destroy action' do
      delete :destroy, {:owner_name => @project.owner.uname, :project_name => @project.name}
      response.should redirect_to(@project.owner)
    end

    it 'should change objects count on destroy' do
      lambda { delete :destroy, :owner_name => @project.owner.uname, :project_name => @project.name }.should change{ Project.count }.by(-1)
    end

    it 'should not be able to fork project' do
      post :fork, :owner_name => @project.owner.uname, :project_name => @project.name
      # @project.errors.count.should == 1
      response.should redirect_to(@project)
    end

  end

  context 'for reader user' do
    before(:each) do
      @user = FactoryGirl.create(:user)
      set_session_for(@user)
      @project.relations.create!(:actor_type => 'User', :actor_id => @user.id, :role => 'reader')
    end

    it_should_behave_like 'projects user with reader rights'
    it_should_behave_like 'user without update rights'
  end

  context 'for writer user' do
    before(:each) do
      @user = FactoryGirl.create(:user)
      set_session_for(@user)
      @project.relations.create!(:actor_type => 'User', :actor_id => @user.id, :role => 'writer')
    end

    it_should_behave_like 'projects user with reader rights'

    it 'should not be able to create project to other group' do
      group = FactoryGirl.create(:group)
      post :create, @create_params.merge({:who_owns => 'group', :owner_id => group.id})
      response.should redirect_to(forbidden_path)
    end

    it 'should not be able to fork project to other group' do
      group = FactoryGirl.create(:group)
      post :fork, :owner_name => @project.owner.uname, :project_name => @project.name, :group => group.id
      response.should redirect_to(forbidden_path)
    end

    it 'should be able to fork project to group' do
      group = FactoryGirl.create(:group)
      group.actors.create(:actor_type => 'User', :actor_id => @user.id, :role => 'admin')
      post :fork, :owner_name => @project.owner.uname, :project_name => @project.name, :group => group.id
      response.should redirect_to(project_path(group.projects.first))
    end
  end

  context 'search projects' do
    before(:each) do
      @admin = FactoryGirl.create(:admin)
      @project1 = FactoryGirl.create(:project, :name => 'perl-debug')
      @project2 = FactoryGirl.create(:project, :name => 'perl')
      set_session_for(@admin)
    end

    pending 'should return projects in right order' do
      get :index, :query => 'per'
      assigns(:projects).should eq([@project2, @project1])
    end
  end

  context 'for other user' do
    before(:each) do
      @user = FactoryGirl.create(:user)
      set_session_for(@user)
    end

    it 'should not be able to fork hidden project' do
      @project.update_attributes(:visibility => 'hidden')
      post :fork, :owner_name => @project.owner.uname, :project_name => @project.name
      response.should redirect_to(forbidden_path)
    end

    it_should_behave_like 'user without update rights'
  end

  context 'for group' do
    before(:each) do
      @group = FactoryGirl.create(:group)
      @group_user = FactoryGirl.create(:user)
      @project.relations.destroy_all
      set_session_for(@group_user)
    end

    context 'owner of the project' do
      before(:each) do
        @project.owner = @group; @project.save!; @project.reload
        @project.relations.create :actor_id => @project.owner.id, :actor_type => @project.owner.class.to_s, :role => 'admin'
      end

      context 'reader user' do
        before(:each) do
          @group.actors.create(:actor_id => @group_user.id, :actor_type => 'User', :role => 'reader')
        end

        it_should_behave_like 'projects user with reader rights'
        it_should_behave_like 'user without update rights'

        it 'should has reader role to group project' do
          @group_user.best_role(@project).should eql('reader') # Need this?
        end

        context 'user should has best role' do
          before(:each) do
            @project.relations.create :actor_id => @group_user.id, :actor_type => @group_user.class.to_s, :role => 'admin'
          end
          it_should_behave_like 'projects user with admin rights'
        end
      end

      context 'admin user' do
        before(:each) do
          @group.actors.create(:actor_id => @group_user.id, :actor_type => 'User', :role => 'admin')
        end

        it_should_behave_like 'projects user with admin rights'
        it_should_behave_like 'projects user with reader rights'
      end
    end

    context 'member of the project' do
      context 'with admin rights' do
        before(:each) do
          @project.relations.create :actor_id => @group.id, :actor_type => @group.class.to_s, :role => 'admin'
        end

        context 'reader user' do
          before(:each) do
            @group.actors.create(:actor_id => @group_user.id, :actor_type => 'User', :role => 'reader')
          end

          it_should_behave_like 'projects user with reader rights'
          it_should_behave_like 'projects user with admin rights'

          context 'user should has best role' do
            before(:each) do
              @project.relations.create :actor_id => @group_user.id, :actor_type => @group_user.class.to_s, :role => 'reader'
            end
            it_should_behave_like 'projects user with admin rights'
          end
        end

        context 'admin user' do
          before(:each) do
            @group.actors.create(:actor_id => @group_user.id, :actor_type => 'User', :role => 'admin')
          end

          it_should_behave_like 'projects user with admin rights'
          it_should_behave_like 'projects user with reader rights'
        end
      end

      context 'with reader rights' do
        before(:each) do
          @project.relations.create :actor_id => @group.id, :actor_type => @group.class.to_s, :role => 'reader'
        end

        context 'reader user' do
          before(:each) do
            @group.actors.create(:actor_id => @group_user.id, :actor_type => 'User', :role => 'reader')
          end

          it_should_behave_like 'projects user with reader rights'
          it_should_behave_like 'user without update rights'

          context 'user should has best role' do
            before(:each) do
              @project.relations.create :actor_id => @group_user.id, :actor_type => @group_user.class.to_s, :role => 'admin'
            end
            it_should_behave_like 'projects user with admin rights'
          end
        end

        context 'admin user' do
          before(:each) do
            @group.actors.create(:actor_id => @group_user.id, :actor_type => 'User', :role => 'admin')
          end

          it_should_behave_like 'projects user with reader rights'
          it_should_behave_like 'user without update rights'
        end
      end
    end
  end
end
