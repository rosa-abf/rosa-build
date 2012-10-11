# -*- encoding : utf-8 -*-
require 'spec_helper'

shared_examples_for "api projects user with reader rights" do
  include_examples "api projects user with show rights"
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
  it "should show access violation instead of project data" do
    get :show, :id => @project.id, :format => :json
    response.should_not be_success
  end

  it "should show access violation instead of project refs_list" do
    get :refs_list, :id => @project.id, :format => :json
    response.should_not be_success
  end

  it "should access violation instead of project data by get_id" do
    get :get_id, :name => @project.name, :owner => @project.owner.uname, :format => :json
    response.should_not be_success
  end
end

shared_examples_for "api projects user with show rights" do
  it "should show project data" do
    get :show, :id => @project.id, :format => :json
    render_template(:show)
  end

  it "should show refs_list of project" do
    get :refs_list, :id => @project.id, :format => :json
    render_template(:refs_list)
  end

  context 'project find by get_id' do
    it "should find project by name and owner name" do
      @project.reload
      get :get_id, :name => @project.name, :owner => @project.owner.uname, :format => :json
      assigns[:project].id.should == @project.id
    end

    it "should not find project by non existing name and owner name" do
      get :get_id, :name => 'NONE_EXISTING_NAME', :owner => @project.owner.uname, :format => :json
      assigns[:project].should be_blank
    end

    it "should render 404 for non existing name and owner name" do
      get :get_id, :name => 'NONE_EXISTING_NAME', :owner => @project.owner.uname, :format => :json
      response.body.should == {:message => I18n.t("flash.404_message")}.to_json
    end
  end
end

describe Api::V1::ProjectsController do

  before(:each) do
    stub_symlink_methods

    @project = FactoryGirl.create(:project)
    @hidden_project = FactoryGirl.create(:project)
    @another_user = FactoryGirl.create(:user)
  end

  context 'for guest' do
    
    if APP_CONFIG['anonymous_access']
      it_should_behave_like 'api projects user with reader rights'
      it_should_behave_like 'api projects user without reader rights for hidden project'
    else
      it_should_behave_like 'api projects user without show rights'
    end

  end

  context 'for simple user' do
    before(:each) do
      @user = FactoryGirl.create(:user)
      http_login(@user)
    end

    it_should_behave_like 'api projects user with reader rights'
    it_should_behave_like 'api projects user without reader rights for hidden project'
  end

  context 'for admin' do
    before(:each) do
      @admin = FactoryGirl.create(:admin)
      http_login(@admin)
    end

    it_should_behave_like 'api projects user with reader rights'
    it_should_behave_like 'api projects user with reader rights for hidden project'
  end

  context 'for owner user' do
    before(:each) do
      @user = FactoryGirl.create(:user)
      http_login(@user)
      @project.owner = @user; @project.save
      @project.relations.create!(:actor_type => 'User', :actor_id => @user.id, :role => 'admin')
    end

    it_should_behave_like 'api projects user with reader rights'
    it_should_behave_like 'api projects user with reader rights for hidden project'
  end

  context 'for reader user' do
    before(:each) do
      @user = FactoryGirl.create(:user)
      http_login(@user)
      @project.relations.create!(:actor_type => 'User', :actor_id => @user.id, :role => 'reader')
    end

    it_should_behave_like 'api projects user with reader rights'
    it_should_behave_like 'api projects user with reader rights for hidden project'
  end

  context 'for writer user' do
    before(:each) do
      @user = FactoryGirl.create(:user)
      http_login(@user)
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
      http_login(@group_user)
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
