require 'spec_helper'

shared_examples_for "api projects user with reader rights" do
  include_examples "api projects user with show rights"
end

shared_examples_for "api projects user with reader rights for hidden project" do
  before do
    project.update_column(:visibility, 'hidden')
  end

  it_should_behave_like 'api projects user with show rights'
end

shared_examples_for "api projects user without reader rights for hidden project" do
  before do
    project.update_column(:visibility, 'hidden')
  end

  it_should_behave_like 'api projects user without show rights'
end

shared_examples_for "api projects user without show rights" do
  it "to show access violation instead of project data" do
    get :show, id: project.id, format: :json
    expect(response).to_not be_success
  end

  it "to show access violation instead of project refs_list" do
    get :refs_list, id: project.id, format: :json
    expect(response).to_not be_success
  end

  it "to access violation instead of project data by get_id" do
    get :get_id, name: project.name, owner: project.owner_uname, format: :json
    expect(response).to_not be_success
  end

  it "to show access violation instead of project members data" do
    get :members, id: project.id, format: :json
    expect(response).to_not be_success
  end

end

shared_examples_for 'api projects user without fork rights' do
  before { project } # init

  it 'to not be able to perform fork action' do
    expect do
      post :fork, id: project.id, format: :json
    end.to_not change(Project, :count)
    expect(response).to_not be_success
  end
end

shared_examples_for 'api projects user with fork rights' do
  before { project } # init

  it 'to be able to perform fork action' do
    expect do
      post :fork, id: project.id, format: :json
    end.to change(Project, :count).by(1)
    expect(response).to be_success
  end

  it 'to be able to perform fork action with different name' do
    new_name = project.name + '_forked'
    expect do
      post :fork, id: project.id, fork_name: new_name, format: :json
    end.to change{ Project.where(name: new_name).count }.by(1)
    expect(response).to be_success
  end
end

shared_examples_for 'api projects user with fork rights for hidden project' do
  before { project.update_column(:visibility, 'hidden') }
  it_should_behave_like 'api projects user with fork rights'
end

shared_examples_for 'api projects user without fork rights for hidden project' do
  before { project.update_column(:visibility, 'hidden') }
  it_should_behave_like 'api projects user without fork rights'
end

shared_examples_for "api projects user with show rights" do
  it "to show project data" do
    get :show, id: project.id, format: :json
    expect(response).to render_template(:show)
  end

  it "to show refs_list of project" do
    get :refs_list, id: project.id, format: :json
    expect(response).to render_template(:refs_list)
  end

  context 'project find by get_id' do
    it "to find project by name and owner name" do
      project.reload
      get :get_id, name: project.name, owner: project.owner_uname, format: :json
      expect(assigns[:project].id).to eq project.id
    end

    it "to not find project by non existing name and owner name" do
      get :get_id, name: 'NONE_EXISTING_NAME', owner: project.owner_uname, format: :json
      expect(assigns :project).to be_blank
    end

    it "to render 404 for non existing name and owner name" do
      get :get_id, name: 'NONE_EXISTING_NAME', owner: project.owner_uname, format: :json
      expect(response.body).to eq({status: 404, message: I18n.t("flash.404_message")}.to_json)
    end
  end
end

shared_examples_for 'api projects user with admin rights' do

  it "to be able to perform members action" do
    get :members, id: project.id, format: :json
    expect(response).to be_success
  end
  it 'to not set a wrong maintainer_id' do
    put :update, project: { maintainer_id: -1 }, id: project.id, format: :json
    expect(response).to_not be_success
  end

  context 'api project user with update rights' do
    before do
      put :update, project: { description: 'new description' }, id: project.id, format: :json
    end

    it 'to be able to perform update action' do
      expect(response).to be_success
      expect(project.reload.description).to eq 'new description'
    end
  end

  context 'api project user with add_member rights' do
    let(:member) { FactoryGirl.create(:user) }
    before do
      put :add_member, member_id: member.id, type: 'User', role: 'admin', id: project.id, format: :json
    end

    it 'to be able to perform add_member action' do
      expect(response).to be_success
      expect(project.members).to include(member)
    end
  end

  context 'api project user with remove_member rights' do
    let(:member) { FactoryGirl.create(:user) }
    before do
      project.add_member(member)
      delete :remove_member, member_id: member.id, type: 'User', id: project.id, format: :json
    end

    it 'to be able to perform remove_member action' do
      expect(response).to be_success
      expect(project.members).to_not include(member)
    end
  end

  context 'api group user with update_member rights' do
    let(:member) { FactoryGirl.create(:user) }
    before do
      project.add_member(member)
      put :update_member, member_id: member.id, type: 'User', role: 'reader', id: project.id, format: :json
    end

    it 'to be able to perform update_member action' do
      expect(response).to be_success
      role = project.relations.by_actor(member).first.role
      expect(role).to eq 'reader'
    end
  end
end

shared_examples_for 'api projects user without admin rights' do

  it "to not be able to perform members action" do
    get :members, id: project.id, format: :json
    expect(response).to_not be_success
  end

  context 'api project user without update_member rights' do
    let(:member) { FactoryGirl.create(:user) }
    before do
      project.add_member(member)
      put :update_member, member_id: member.id, type: 'User', role: 'reader', id: project.id, format: :json
    end

    it 'to not be able to perform update_member action' do
      expect(response).to_not be_success
      role = project.relations.by_actor(member).first.role
      expect(role).to_not eq 'reader'
    end
  end

  context 'api project user without update rights' do
    before do
      put :update, project: {description: 'new description'}, id: project.id, format: :json
    end

    it 'to not be able to perform update action' do
      expect(response).to_not be_success
      expect(project.reload.description).to_not eq 'new description'
    end
  end

  context 'api project user without add_member rights' do
    let(:member) { FactoryGirl.create(:user) }
    before do
      put :add_member, member_id: member.id, type: 'User', role: 'admin', id: project.id, format: :json
    end

    it 'to not be able to perform add_member action' do
      expect(response).to_not be_success
      expect(project.members).to_not include(member)
    end
  end

  context 'api project user without remove_member rights' do
    let(:member) { FactoryGirl.create(:user) }
    before do
      project.add_member(member)
      delete :remove_member, member_id: member.id, type: 'User', id: project.id, format: :json
    end

    it 'to be able to perform update action' do
      expect(response).to_not be_success
      expect(project.members).to include(member)
    end
  end
end

shared_examples_for 'api projects user with owner rights' do
  before { project } # init

  context 'api project user with destroy rights' do
    it 'to be able to perform destroy action' do
      expect do
        delete :destroy, id: project.id, format: :json
      end.to change(Project, :count).by(-1)
      expect(response).to be_success
    end
  end
end

shared_examples_for 'api projects user without owner rights' do
  before { project } # init

  context 'api project user with destroy rights' do
    it 'to not be able to perform destroy action' do
      expect do
        delete :destroy, id: project.id, format: :json
      end.to_not change(Project, :count)
      expect(response).to_not be_success
    end
  end
end

describe Api::V1::ProjectsController, type: :controller do

  let(:project)        { FactoryGirl.create(:project) }
  let(:hidden_project) { FactoryGirl.create(:project) }
  let(:another_user)   { FactoryGirl.create(:user) }

  before do
    stub_symlink_methods

    # project = FactoryGirl.create(:project)
    # hidden_project = FactoryGirl.create(:project)
    # another_user = FactoryGirl.create(:user)
  end

  context 'for guest' do

    [:index, :members].each do |action|
      it "to not be able to perform #{action} action" do
        get action, id: project.id, format: :json
        expect(response).to_not be_success
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
    let(:user) { FactoryGirl.create(:user) }

    before do
      http_login(user)
    end

    it 'to be able to perform index action' do
      get :index, format: :json
      expect(response).to be_success
    end

    context 'api project user with create rights' do
      let(:params) { {project: {name: 'test_name', owner_id: user.id, owner_type: 'User', visibility: 'open'}, format: :json} }
      it 'to be able to perform create action' do
        post :create, params, format: :json
        expect(response).to be_success
      end
      it 'ensures that project has been created' do
        expect do
          post :create, params
        end.to change(Project, :count).by(1)
      end

      it 'writer group to be able to create project for their group' do
        group = FactoryGirl.create(:group)
        create_actor_relation(group, user, 'writer')
        expect do
          post :create, params.deep_merge({project: {owner_type: 'Group', owner_id: group.id}})
        end.to change(Project, :count).by(1)
      end

      it 'reader group to not be able to create project for their group' do
        group = FactoryGirl.create(:group)
        create_actor_relation(group, user, 'reader')
        expect do
          post :create, params.deep_merge({project: {owner_type: 'Group', owner_id: group.id}})
        end.to_not change(Project, :count)
      end
    end

    it_should_behave_like 'api projects user with reader rights'
    it_should_behave_like 'api projects user without reader rights for hidden project'
    it_should_behave_like 'api projects user with fork rights'
    it_should_behave_like 'api projects user without fork rights for hidden project'
    it_should_behave_like 'api projects user without admin rights'
    it_should_behave_like 'api projects user without owner rights'

    context 'group writer' do
      before { project } # init

      it 'to be able to fork project to their group' do
        group = FactoryGirl.create(:group)
        create_actor_relation(group, user, 'writer')
        expect do
          post :fork, id: project.id, group_id: group.id, format: :json
        end.to change(Project, :count).by(1)
      end

      it 'to be able to fork project with different name to their group' do
        group = FactoryGirl.create(:group)
        create_actor_relation(group, user, 'writer')
        new_name = project.name + '_forked'
        expect do
          post :fork, id: project.id, group_id: group.id, fork_name: new_name, format: :json
        end.to change { Project.where(name: new_name).count }.by(1)
      end
    end

    context 'group reader' do
      before { project } # init

      it 'to not be able to fork project to their group' do
        group = FactoryGirl.create(:group)
        create_actor_relation(group, user, 'reader')
        expect do
          post :fork, id: project.id, group_id: group.id, format: :json
        end.to_not change(Project, :count)
      end

      it 'to not be able to fork project with different name to their group' do
        group = FactoryGirl.create(:group)
        new_name = project.name + '_forked'
        create_actor_relation(group, user, 'reader')
        expect do
          post :fork, id: project.id, group_id: group.id, fork_name: new_name, format: :json
        end.to_not change{ Project.where(name: new_name).count }
      end
    end
  end

  context 'for admin' do
    let(:admin) { FactoryGirl.create(:admin) }

    before do
      http_login(admin)
    end

    it_should_behave_like 'api projects user with reader rights'
    it_should_behave_like 'api projects user with reader rights for hidden project'
    it_should_behave_like 'api projects user with fork rights'
    it_should_behave_like 'api projects user with fork rights for hidden project'
    it_should_behave_like 'api projects user with admin rights'
    it_should_behave_like 'api projects user with owner rights'
  end

  context 'for owner user' do
    let(:user)    { FactoryGirl.create(:user) }
    let(:project) { FactoryGirl.create(:project, owner: user) }

    before do
      http_login(user)
    end

    it_should_behave_like 'api projects user with reader rights'
    it_should_behave_like 'api projects user with reader rights for hidden project'
    it_should_behave_like 'api projects user without fork rights'
    it_should_behave_like 'api projects user without fork rights for hidden project'
    it_should_behave_like 'api projects user with admin rights'
    it_should_behave_like 'api projects user with owner rights'
  end

  context 'for reader user' do
    let(:user) { FactoryGirl.create(:user) }

    before do
      http_login(user)
      create_relation(project, user, 'reader')
    end

    it_should_behave_like 'api projects user with reader rights'
    it_should_behave_like 'api projects user with reader rights for hidden project'
    it_should_behave_like 'api projects user with fork rights'
    it_should_behave_like 'api projects user with fork rights for hidden project'
    it_should_behave_like 'api projects user without admin rights'
    it_should_behave_like 'api projects user without owner rights'
  end

  context 'for writer user' do
    let(:user) { FactoryGirl.create(:user) }

    before do
      http_login(user)
      create_relation(project, user, 'writer')
    end

    it_should_behave_like 'api projects user with reader rights'
    it_should_behave_like 'api projects user with reader rights for hidden project'
    it_should_behave_like 'api projects user with fork rights'
    it_should_behave_like 'api projects user with fork rights for hidden project'
    it_should_behave_like 'api projects user without admin rights'
    it_should_behave_like 'api projects user without owner rights'
  end

  context 'for group' do
    let(:group) { FactoryGirl.create(:group) }
    let(:group_user) { FactoryGirl.create(:user) }

    before do
#      project.relations.destroy_all
      http_login(group_user)
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
      let(:project) { FactoryGirl.create(:project, owner: group) }

      context 'reader user' do
        before { create_actor_relation(group, group_user, 'reader') }

        it_should_behave_like 'api projects user with reader rights'
        it_should_behave_like 'api projects user with reader rights for hidden project'
        it_should_behave_like 'api projects user with fork rights'
        it_should_behave_like 'api projects user with fork rights for hidden project'
        it_should_behave_like 'api projects user without admin rights'
        it_should_behave_like 'api projects user without owner rights'
      end

      context 'admin user' do
        before { create_actor_relation(group, group_user, 'admin') }

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
        before do
          create_relation(project, group, 'admin')
        end

        context 'reader user' do
          before { create_actor_relation(group, group_user, 'reader') }

          it_should_behave_like 'api projects user with reader rights'
          it_should_behave_like 'api projects user with reader rights for hidden project'
          it_should_behave_like 'api projects user with fork rights'
          it_should_behave_like 'api projects user with fork rights for hidden project'
          it_should_behave_like 'api projects user with admin rights'
          it_should_behave_like 'api projects user without owner rights'
        end

        context 'admin user' do
          before { create_actor_relation(group, group_user, 'admin') }

          it_should_behave_like 'api projects user with reader rights'
          it_should_behave_like 'api projects user with reader rights for hidden project'
          it_should_behave_like 'api projects user with fork rights'
          it_should_behave_like 'api projects user with fork rights for hidden project'
          it_should_behave_like 'api projects user with admin rights'
          it_should_behave_like 'api projects user without owner rights'
        end
      end

      context 'with reader rights' do
        before { create_relation(project, group, 'reader') }

        context 'reader user' do
          before { create_actor_relation(group, group_user, 'reader') }

          it_should_behave_like 'api projects user with reader rights'
          it_should_behave_like 'api projects user with reader rights for hidden project'
          it_should_behave_like 'api projects user with fork rights'
          it_should_behave_like 'api projects user with fork rights for hidden project'
          it_should_behave_like 'api projects user without admin rights'
          it_should_behave_like 'api projects user without owner rights'

          context 'user should has best role' do
            before { create_relation(project, group_user, 'admin') }

            it_should_behave_like 'api projects user with reader rights'
            it_should_behave_like 'api projects user with fork rights'
            it_should_behave_like 'api projects user with fork rights for hidden project'
            it_should_behave_like 'api projects user with admin rights'
            it_should_behave_like 'api projects user without owner rights'
          end
        end


        context 'admin user' do
          before { create_actor_relation(group, group_user, 'admin') }

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
