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
    get :show, id: @project.id, format: :json
    response.should_not be_success
  end

  it "should show access violation instead of project refs_list" do
    get :refs_list, id: @project.id, format: :json
    response.should_not be_success
  end

  it "should access violation instead of project data by get_id" do
    get :get_id, name: @project.name, owner: @project.owner.uname, format: :json
    response.should_not be_success
  end

  it "should show access violation instead of project members data" do
    get :members, id: @project.id, format: :json
    response.should_not be_success
  end

end

shared_examples_for 'api projects user without fork rights' do
  it 'should not be able to perform fork action' do
    post :fork, id: @project.id, format: :json
    response.should_not be_success
  end
  it 'ensures that project has not been forked' do
    lambda { post :fork, id: @project.id, format: :json }.should_not change{ Project.count }
  end
end

shared_examples_for 'api projects user with fork rights' do
  it 'should be able to perform fork action' do
    post :fork, id: @project.id, format: :json
    response.should be_success
  end
  it 'ensures that project has been forked' do
    lambda { post :fork, id: @project.id, format: :json }.should change{ Project.count }.by(1)
  end

  it 'should be able to perform fork action with different name' do
    post :fork, id: @project.id, fork_name: (@project.name + '_forked'), format: :json
    response.should be_success
  end

  it 'ensures that project has been forked' do
    new_name = @project.name + '_forked'
    lambda { post :fork, id: @project.id, fork_name: new_name, format: :json }.should
      change{ Project.where(name: new_name).count }.by(1)
  end
end

shared_examples_for 'api projects user with fork rights for hidden project' do
  before { @project.update_column(:visibility, 'hidden') }
  it_should_behave_like 'api projects user with fork rights'
end

shared_examples_for 'api projects user without fork rights for hidden project' do
  before { @project.update_column(:visibility, 'hidden') }
  it_should_behave_like 'api projects user without fork rights'
end

shared_examples_for "api projects user with show rights" do
  it "should show project data" do
    get :show, id: @project.id, format: :json
    render_template(:show)
  end

  it "should show refs_list of project" do
    get :refs_list, id: @project.id, format: :json
    render_template(:refs_list)
  end

  context 'project find by get_id' do
    it "should find project by name and owner name" do
      @project.reload
      get :get_id, name: @project.name, owner: @project.owner.uname, format: :json
      assigns[:project].id.should == @project.id
    end

    it "should not find project by non existing name and owner name" do
      get :get_id, name: 'NONE_EXISTING_NAME', owner: @project.owner.uname, format: :json
      assigns[:project].should be_blank
    end

    it "should render 404 for non existing name and owner name" do
      get :get_id, name: 'NONE_EXISTING_NAME', owner: @project.owner.uname, format: :json
      response.body.should == {status: 404, message: I18n.t("flash.404_message")}.to_json
    end
  end
end

shared_examples_for 'api projects user with admin rights' do

  it "should be able to perform members action" do
    get :members, id: @project.id, format: :json
    response.should be_success
  end

  context 'api project user with update rights' do
    before do
      put :update, {project: {description: 'new description'}, id: @project.id}, format: :json
    end

    it 'should be able to perform update action' do
      response.should be_success
    end
    it 'ensures that group has been updated' do
      @project.reload
      @project.description.should == 'new description'
    end
  end

  context 'api project user with add_member rights' do
    let(:member) { FactoryGirl.create(:user) }
    before do
      put :add_member, {member_id: member.id, type: 'User', role: 'admin', id: @project.id}, format: :json
    end

    it 'should be able to perform add_member action' do
      response.should be_success
    end
    it 'ensures that new member has been added to project' do
      @project.members.should include(member)
    end
  end

  context 'api project user with remove_member rights' do
    let(:member) { FactoryGirl.create(:user) }
    before do
      @project.add_member(member)
      delete :remove_member, {member_id: member.id, type: 'User', id: @project.id}, format: :json
    end

    it 'should be able to perform remove_member action' do
      response.should be_success
    end
    it 'ensures that member has been removed from project' do
      @project.members.should_not include(member)
    end
  end

  context 'api group user with update_member rights' do
    let(:member) { FactoryGirl.create(:user) }
    before do
      @project.add_member(member)
      put :update_member, {member_id: member.id, type: 'User', role: 'reader', id: @project.id}, format: :json
    end

    it 'should be able to perform update_member action' do
      response.should be_success
    end
    it 'ensures that member role has been updated in project' do
      @project.relations.by_actor(member).first.
        role.should == 'reader'
    end
  end
end

shared_examples_for 'api projects user without admin rights' do

  it "should not be able to perform members action" do
    get :members, id: @project.id, format: :json
    response.should_not be_success
  end

  context 'api project user without update_member rights' do
    let(:member) { FactoryGirl.create(:user) }
    before do
      @project.add_member(member)
      put :update_member, {member_id: member.id, type: 'User', role: 'reader', id: @project.id}, format: :json
    end

    it 'should not be able to perform update_member action' do
      response.should_not be_success
    end
    it 'ensures that member role has not been updated in project' do
      @project.relations.by_actor(member).first.
        role.should_not == 'reader'
    end
  end

  context 'api project user without update rights' do
    before do
      put :update, {project: {description: 'new description'}, id: @project.id}, format: :json
    end

    it 'should not be able to perform update action' do
      response.should_not be_success
    end
    it 'ensures that project has not been updated' do
      @project.reload
      @project.description.should_not == 'new description'
    end
  end

  context 'api project user without add_member rights' do
    let(:member) { FactoryGirl.create(:user) }
    before do
      put :add_member, {member_id: member.id, type: 'User', role: 'admin', id: @project.id}, format: :json
    end

    it 'should not be able to perform add_member action' do
      response.should_not be_success
    end
    it 'ensures that new member has not been added to project' do
      @project.members.should_not include(member)
    end
  end

  context 'api project user without remove_member rights' do
    let(:member) { FactoryGirl.create(:user) }
    before do
      @project.add_member(member)
      delete :remove_member, {member_id: member.id, type: 'User', id: @project.id}, format: :json
    end

    it 'should be able to perform update action' do
      response.should_not be_success
    end
    it 'ensures that member has not been removed from project' do
      @project.members.should include(member)
    end
  end
end

shared_examples_for 'api projects user with owner rights' do
  context 'api project user with destroy rights' do
    it 'should be able to perform destroy action' do
      delete :destroy, id: @project.id, format: :json
      response.should be_success
    end
    it 'ensures that project has been destroyed' do
      lambda { delete :destroy, id: @project.id, format: :json }.should change{ Project.count }.by(-1)
    end
  end
end

shared_examples_for 'api projects user without owner rights' do
  context 'api project user with destroy rights' do
    it 'should not be able to perform destroy action' do
      delete :destroy, id: @project.id, format: :json
      response.should_not be_success
    end
    it 'ensures that project has not been destroyed' do
      lambda { delete :destroy, id: @project.id, format: :json }.should_not change{ Project.count }
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

    [:index, :members].each do |action|
      it "should not be able to perform #{action} action" do
        get action, id: @project.id, format: :json
        response.should_not be_success
      end
    end

    if APP_CONFIG['anonymous_access']
      it_should_behave_like 'api projects user with show rights'
      it_should_behave_like 'api projects user without reader rights for hidden project'
    else
      it_should_behave_like 'api projects user without show rights'
    end
    it_should_behave_like 'api projects user without fork rights'
    it_should_behave_like 'api projects user without fork rights for hidden project'
    it_should_behave_like 'api projects user without admin rights'
    it_should_behave_like 'api projects user without owner rights'
  end

  context 'for simple user' do
    before(:each) do
      @user = FactoryGirl.create(:user)
      http_login(@user)
    end

    it 'should be able to perform index action' do
      get :index, format: :json
      response.should be_success
    end

    context 'api project user with create rights' do
      let(:params) { {project: {name: 'test_name', owner_id: @user.id, owner_type: 'User', visibility: 'open'}} }
      it 'should be able to perform create action' do
        post :create, params, format: :json
        response.should be_success
      end
      it 'ensures that project has been created' do
        lambda { post :create, params, format: :json }.should change{ Project.count }.by(1)
      end

      it 'writer group should be able to create project for their group' do
        group = FactoryGirl.create(:group)
        create_actor_relation(group, @muser, 'writer')
        lambda { post :create, params.deep_merge({project: {owner_type: 'Group', owner_id: group.id}})}.should change{ Project.count }.by(1)
      end

      it 'reader group should not be able to create project for their group' do
        group = FactoryGirl.create(:group)
        create_actor_relation(@group, @user, 'reader')
        lambda { post :create, params.deep_merge({project: {owner_type: 'Group', owner_id: group.id}})}.should change{ Project.count }.by(0)
      end
    end

    it_should_behave_like 'api projects user with reader rights'
    it_should_behave_like 'api projects user without reader rights for hidden project'
    it_should_behave_like 'api projects user with fork rights'
    it_should_behave_like 'api projects user without fork rights for hidden project'
    it_should_behave_like 'api projects user without admin rights'
    it_should_behave_like 'api projects user without owner rights'

    context 'group writer' do
      it 'should be able to fork project to their group' do
        group = FactoryGirl.create(:group)
        create_actor_relation(group, @user, 'writer')
        lambda {post :fork, id: @project.id, group_id: group.id}.should change{ Project.count }.by(1)
      end

      it 'should be able to fork project with different name to their group' do
        group = FactoryGirl.create(:group)
        create_actor_relation(group, @user, 'writer')
        new_name = @project.name + '_forked'
        lambda { post :fork, id: @project.id, group_id: group.id, fork_name: new_name }.should
          change { Project.where(name: new_name).count }.by(1)
      end
    end

    context 'group reader' do
      it 'should not be able to fork project to their group' do
        group = FactoryGirl.create(:group)
        create_actor_relation(group, @user, 'reader')
        lambda {post :fork, id: @project.id, group_id: group.id}.should change{ Project.count }.by(0)
      end

      it 'should not be able to fork project with different name to their group' do
        group = FactoryGirl.create(:group)
        new_name = @project.name + '_forked'
        create_actor_relation(group, @user, 'reader')
        lambda { post :fork, id: @project.id, group_id: group.id, fork_name: new_name }.should
          change{ Project.where(name: new_name.count) }.by(0)
      end
    end
  end

  context 'for admin' do
    before(:each) do
      @admin = FactoryGirl.create(:admin)
      http_login(@admin)
    end

    it_should_behave_like 'api projects user with reader rights'
    it_should_behave_like 'api projects user with reader rights for hidden project'
    it_should_behave_like 'api projects user with fork rights'
    it_should_behave_like 'api projects user with fork rights for hidden project'
    it_should_behave_like 'api projects user with admin rights'
    it_should_behave_like 'api projects user with owner rights'
  end

  context 'for owner user' do
    before(:each) do
      @user = FactoryGirl.create(:user)
      http_login(@user)
      @project = FactoryGirl.create(:project, owner: @user)
    end

    it_should_behave_like 'api projects user with reader rights'
    it_should_behave_like 'api projects user with reader rights for hidden project'
    it_should_behave_like 'api projects user without fork rights'
    it_should_behave_like 'api projects user without fork rights for hidden project'
    it_should_behave_like 'api projects user with admin rights'
    it_should_behave_like 'api projects user with owner rights'
  end

  context 'for reader user' do
    before(:each) do
      @user = FactoryGirl.create(:user)
      http_login(@user)
      create_relation(@project, @user, 'reader')
    end

    it_should_behave_like 'api projects user with reader rights'
    it_should_behave_like 'api projects user with reader rights for hidden project'
    it_should_behave_like 'api projects user with fork rights'
    it_should_behave_like 'api projects user with fork rights for hidden project'
    it_should_behave_like 'api projects user without admin rights'
    it_should_behave_like 'api projects user without owner rights'
  end

  context 'for writer user' do
    before(:each) do
      @user = FactoryGirl.create(:user)
      http_login(@user)
      create_relation(@project, @user, 'writer')
    end

    it_should_behave_like 'api projects user with reader rights'
    it_should_behave_like 'api projects user with reader rights for hidden project'
    it_should_behave_like 'api projects user with fork rights'
    it_should_behave_like 'api projects user with fork rights for hidden project'
    it_should_behave_like 'api projects user without admin rights'
    it_should_behave_like 'api projects user without owner rights'
  end

  context 'for group' do
    before(:each) do
      @group = FactoryGirl.create(:group)
      @group_user = FactoryGirl.create(:user)
#      @project.relations.destroy_all
      http_login(@group_user)
    end

    context 'with no relations to project' do
      it_should_behave_like 'api projects user with reader rights'
      it_should_behave_like 'api projects user without reader rights for hidden project'
      it_should_behave_like 'api projects user with fork rights'
      it_should_behave_like 'api projects user without fork rights for hidden project'
      it_should_behave_like 'api projects user without admin rights'
      it_should_behave_like 'api projects user without owner rights'
    end

    context 'owner of the project' do
      before(:each) do
        @project = FactoryGirl.create(:project, owner: @group)
      end

      context 'reader user' do
        before(:each) { create_actor_relation(@group, @group_user, 'reader') }

        it_should_behave_like 'api projects user with reader rights'
        it_should_behave_like 'api projects user with reader rights for hidden project'
        it_should_behave_like 'api projects user with fork rights'
        it_should_behave_like 'api projects user with fork rights for hidden project'
        it_should_behave_like 'api projects user without admin rights'
        it_should_behave_like 'api projects user without owner rights'
      end

      context 'admin user' do
        before(:each) { create_actor_relation(@group, @group_user, 'admin') }

        it_should_behave_like 'api projects user with reader rights'
        it_should_behave_like 'api projects user with reader rights for hidden project'
        it_should_behave_like 'api projects user with fork rights'
        it_should_behave_like 'api projects user with fork rights for hidden project'
        it_should_behave_like 'api projects user with admin rights'
        it_should_behave_like 'api projects user with owner rights'
      end
    end

    context 'member of the project' do
      context 'with admin rights' do
        before(:each) do
          create_relation(@project, @group, 'admin')
        end

        context 'reader user' do
          before(:each) { create_actor_relation(@group, @group_user, 'reader') }

          it_should_behave_like 'api projects user with reader rights'
          it_should_behave_like 'api projects user with reader rights for hidden project'
          it_should_behave_like 'api projects user with fork rights'
          it_should_behave_like 'api projects user with fork rights for hidden project'
          it_should_behave_like 'api projects user with admin rights'
          it_should_behave_like 'api projects user without owner rights'
        end

        context 'admin user' do
          before(:each) { create_actor_relation(@group, @group_user, 'admin') }

          it_should_behave_like 'api projects user with reader rights'
          it_should_behave_like 'api projects user with reader rights for hidden project'
          it_should_behave_like 'api projects user with fork rights'
          it_should_behave_like 'api projects user with fork rights for hidden project'
          it_should_behave_like 'api projects user with admin rights'
          it_should_behave_like 'api projects user without owner rights'
        end
      end

      context 'with reader rights' do
        before(:each) { create_relation(@project, @group, 'reader') }

        context 'reader user' do
          before(:each) { create_actor_relation(@group, @group_user, 'reader') }

          it_should_behave_like 'api projects user with reader rights'
          it_should_behave_like 'api projects user with reader rights for hidden project'
          it_should_behave_like 'api projects user with fork rights'
          it_should_behave_like 'api projects user with fork rights for hidden project'
          it_should_behave_like 'api projects user without admin rights'
          it_should_behave_like 'api projects user without owner rights'

          context 'user should has best role' do
            before(:each) { create_relation(@project, @group_user, 'admin') }

            it_should_behave_like 'api projects user with reader rights'
            it_should_behave_like 'api projects user with fork rights'
            it_should_behave_like 'api projects user with fork rights for hidden project'
            it_should_behave_like 'api projects user with admin rights'
            it_should_behave_like 'api projects user without owner rights'
          end
        end

        context 'admin user' do
          before(:each) { create_actor_relation(@group, @group_user, 'admin') }

          it_should_behave_like 'api projects user with reader rights'
          it_should_behave_like 'api projects user with reader rights for hidden project'
          it_should_behave_like 'api projects user with fork rights'
          it_should_behave_like 'api projects user with fork rights for hidden project'
          it_should_behave_like 'api projects user without admin rights'
          it_should_behave_like 'api projects user without owner rights'
        end
      end
    end
  end
end
