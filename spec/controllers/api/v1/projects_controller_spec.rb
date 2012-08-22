# -*- encoding : utf-8 -*-
require 'spec_helper'

shared_examples_for "api projects user with reader rights" do
  include_examples "api projects user with show rights"

  it "should render index template" do
    get :index, :format => :json
    render_template(:index)
  end
end

shared_examples_for "api projects user with reader rights for hidden project" do
  before(:each) do
    @project.update_column(:visibility, 'hidden')
  end

  it_should_behave_like 'api projects user with show rights'
end

shared_examples_for "api projects user without reader rights for hidden project" do
  before(:each) do
    @project.update_column(:visibility, 'hidden')
  end

  it_should_behave_like 'api projects user without show rights'
end

shared_examples_for "api projects user without show rights" do
  it "should not show project data" do
    get :show, :id => @project.id, :format => :json
    response.body.should == {"message" => "Access violation to this page!"}.to_json
  end
end

shared_examples_for "api projects user with show rights" do
  it "should show project data" do
    get :show, :id => @project.id, :format => :json
    render_template(:show)
  end
end

describe Api::V1::ProjectsController do

  before(:each) do
    stub_symlink_methods

    @project = FactoryGirl.create(:project)
    @hidden_project = FactoryGirl.create(:project)
    @another_user = FactoryGirl.create(:user)
  end

  #TODO: Find out how it works (why it only sets 401 status without redirect on .json)
  context 'for guest' do
    it 'should not be able to perform index action' do
      get :index, :format => :json
      response.status.should == 401
    end

    it 'should not be able to perform show action' do
      get :show, :id => @project.id, :format => :json
      response.status.should == 401
    end
  end

  context 'for simple user' do
    before(:each) do
      @user = FactoryGirl.create(:user)
      set_session_for(@user)
    end

    it_should_behave_like 'api projects user with reader rights'
    it_should_behave_like 'api projects user without reader rights for hidden project'
  end

  context 'for admin' do
    before(:each) do
      @admin = FactoryGirl.create(:admin)
      set_session_for(@admin)
    end

    it_should_behave_like 'api projects user with reader rights'
    it_should_behave_like 'api projects user with reader rights for hidden project'
  end

  context 'for owner user' do
    before(:each) do
      @user = FactoryGirl.create(:user)
      set_session_for(@user)
      @project.owner = @user; @project.save
      @project.relations.create!(:actor_type => 'User', :actor_id => @user.id, :role => 'admin')
    end

    it_should_behave_like 'api projects user with reader rights'
    it_should_behave_like 'api projects user with reader rights for hidden project'
  end

  context 'for reader user' do
    before(:each) do
      @user = FactoryGirl.create(:user)
      set_session_for(@user)
      @project.relations.create!(:actor_type => 'User', :actor_id => @user.id, :role => 'reader')
    end

    it_should_behave_like 'api projects user with reader rights'
    it_should_behave_like 'api projects user with reader rights for hidden project'
  end

  context 'for writer user' do
    before(:each) do
      @user = FactoryGirl.create(:user)
      set_session_for(@user)
      @project.relations.create!(:actor_type => 'User', :actor_id => @user.id, :role => 'writer')
    end

    it_should_behave_like 'api projects user with reader rights'
    it_should_behave_like 'api projects user with reader rights for hidden project'
  end

  context 'for group' do
    before(:each) do
      @group = FactoryGirl.create(:group)
      @group_user = FactoryGirl.create(:user)
      @project.relations.destroy_all
      set_session_for(@group_user)
    end

    context 'with no relations to project' do
      it_should_behave_like 'api projects user with reader rights'
      it_should_behave_like 'api projects user without reader rights for hidden project'
    end

    context 'owner of the project' do
      before(:each) do
        @project.owner = @group; @project.save
        @project.relations.create :actor_id => @project.owner.id, :actor_type => @project.owner.class.to_s, :role => 'admin'
      end

      context 'reader user' do
        before(:each) do
          @group.actors.create(:actor_id => @group_user.id, :actor_type => 'User', :role => 'reader')
        end

        it_should_behave_like 'api projects user with reader rights'
        it_should_behave_like 'api projects user with reader rights for hidden project'
      end

      context 'admin user' do
        before(:each) do
          @group.actors.create(:actor_id => @group_user.id, :actor_type => 'User', :role => 'admin')
        end

        it_should_behave_like 'api projects user with reader rights'
        it_should_behave_like 'api projects user with reader rights for hidden project'
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

          it_should_behave_like 'api projects user with reader rights'
          it_should_behave_like 'api projects user with reader rights for hidden project'
        end

        context 'admin user' do
          before(:each) do
            @group.actors.create(:actor_id => @group_user.id, :actor_type => 'User', :role => 'admin')
          end

          it_should_behave_like 'api projects user with reader rights'
          it_should_behave_like 'api projects user with reader rights for hidden project'
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

          it_should_behave_like 'api projects user with reader rights'
          it_should_behave_like 'api projects user with reader rights for hidden project'

          context 'user should has best role' do
            before(:each) do
              @project.relations.create :actor_id => @group_user.id, :actor_type => @group_user.class.to_s, :role => 'admin'
            end
          it_should_behave_like 'api projects user with reader rights'
          end
        end

        context 'admin user' do
          before(:each) do
            @group.actors.create(:actor_id => @group_user.id, :actor_type => 'User', :role => 'admin')
          end

          it_should_behave_like 'api projects user with reader rights'
          it_should_behave_like 'api projects user with reader rights for hidden project'
        end
      end
    end
  end
end
