require 'spec_helper'

shared_examples_for 'user with change projects in repository rights' do

  it 'should be able to see add_project page' do
    get :add_project, id: @repository, platform_id: @platform
    expect(response).to render_template(:projects_list)
  end

  it 'should be able to add project to repository' do
    get :add_project, id: @repository, platform_id: @platform, project_id: @project.id
    expect(response).to redirect_to(platform_repository_path(@repository.platform, @repository))
    expect(@repository.projects).to include(@project)
  end

  it 'should be able to remove project from repository' do
    get :remove_project, id: @repository, platform_id: @platform, project_id: @project.id
    expect(response).to redirect_to(platform_repository_path(@repository.platform, @repository))
    expect(@repository.projects).to_not include(@project)
  end

end

shared_examples_for 'user with rights of add/remove sync_lock_file to repository' do
  it 'should be able to perform sync_lock_file action' do
    put :sync_lock_file, id: @repository, platform_id: @platform
    expect(response).to redirect_to(edit_platform_repository_path(@platform, @repository))
  end
end

shared_examples_for 'user without rights of add/remove sync_lock_file to repository' do
  it 'should not be able to perform sync_lock_file action' do
    put :sync_lock_file, id: @repository, platform_id: @platform
    expect(response).to redirect_to(redirect_path)
  end
end

shared_examples_for 'user without change projects in repository rights' do
  it 'should not be able to add project to repository' do
    get :add_project, id: @repository, platform_id: @platform, project_id: @project.id
    expect(response).to redirect_to(redirect_path)
    expect(@repository.projects).to_not include(@project)
  end

  it 'should not be able to perform regenerate_metadata action' do
    put :regenerate_metadata, id: @repository, platform_id: @platform
    expect(response).to redirect_to(redirect_path)
    expect(@repository.repository_statuses.count).to eq 0
  end

  it 'should not be able to remove project from repository' do
    delete :remove_project, id: @repository, platform_id: @platform, project_id: @project.id
    expect(response).to redirect_to(redirect_path)
    expect(@repository.projects).to_not include(@project)
  end
end

shared_examples_for 'registered user or guest' do
  it 'should not be able to perform new action' do
    get :new, platform_id: @platform
    expect(response).to redirect_to(redirect_path)
  end

  it 'should not be able to perform regenerate_metadata action' do
    put :regenerate_metadata, id: @repository, platform_id: @platform
    expect(response).to redirect_to(redirect_path)
    expect(@repository.repository_statuses.count).to eq 0
  end

  it 'should not be able to perform regenerate_metadata action of personal repository' do
    put :regenerate_metadata, id: @personal_repository, platform_id: @personal_repository.platform
    expect(response).to redirect_to(redirect_path)
    expect(@personal_repository.repository_statuses.count).to eq 0
  end

  it 'should not be able to perform create action' do
    post :create, @create_params
    expect do
      post :create, @create_params
    end.to_not change(Repository, :count)
    expect(response).to redirect_to(redirect_path)
  end

  it 'should not be able to perform edit action' do
    get :edit, id: @repository, platform_id: @platform
    expect(response).to redirect_to(redirect_path)
  end

  it 'should not be able to perform update action' do
    put :update, id: @repository, platform_id: @platform
    expect(response).to redirect_to(redirect_path)
  end

  it 'should not be able to add new member to repository' do
    post :add_member, id: @repository, platform_id: @platform, member_id: @another_user.id
    expect(response).to redirect_to(redirect_path)
    expect(@repository.members).to_not include(@another_user)
  end

  it 'should not be able to remove members from repository' do
    another_user2 = FactoryGirl.create(:user)
    create_relation(@repository, @another_user, 'admin')
    create_relation(@repository, another_user2, 'admin')
    post :remove_members, id: @repository, platform_id: @platform,
      members: [@another_user.id, another_user2.id]
    expect(response).to redirect_to(redirect_path)
    expect(@repository.members).to include(@another_user, another_user2)
  end

  it 'should not be able to destroy repository in main platform' do
    delete :destroy, id: @repository, platform_id: @platform
    expect(response).to redirect_to(redirect_path)
    expect do
      delete :destroy, id: @repository, platform_id: @platform
    end.to_not change(Repository, :count)
  end

  it 'should not be able to destroy personal repository' do
    expect do
      delete :destroy, id: @personal_repository, platform_id: @personal_repository.platform
    end.to_not change(Repository, :count)
    expect(response).to redirect_to(redirect_path)
  end
end

shared_examples_for 'registered user' do
  it 'should be able to perform index action' do
    get :index, platform_id: @platform
    expect(response).to render_template(:index)
  end

  it 'should be able to perform show action' do
    get :show, id: @repository, platform_id: @platform
    expect(response).to render_template(:show)
  end

  it 'should be able to perform projects_list action' do
    get :projects_list, id: @repository, platform_id: @platform, format: :json
    expect(response).to be_success
  end

end

shared_examples_for 'platform admin user' do

  it_should_behave_like 'registered user'
  it_should_behave_like 'user with rights of add/remove sync_lock_file to repository'

  it 'should be able to perform new action' do
    get :new, platform_id: @platform
    expect(response).to render_template(:new)
  end

  it 'should be able to perform regenerate_metadata action' do
    put :regenerate_metadata, id: @repository, platform_id: @platform
    expect(response).to redirect_to(platform_repository_path(@platform, @repository))
    expect(@repository.repository_statuses.find_by(platform_id: @platform).
      waiting_for_regeneration?).to be_truthy
  end

  it 'should be able to perform regenerate_metadata action of personal repository' do
    put :regenerate_metadata, id: @personal_repository, platform_id: @personal_repository.platform,
        repository: { build_for_platform_id: @platform.id }
    expect(response).to redirect_to(platform_repository_path(@personal_repository.platform, @personal_repository))
    expect(@personal_repository.repository_statuses.find_by(platform_id: @platform).
      waiting_for_regeneration?).to be_truthy
  end

  it 'should not be able to perform regenerate_metadata action of personal repository when build_for_platform does not exist' do
    put :regenerate_metadata, id: @personal_repository, platform_id: @personal_repository.platform
    expect(response).to render_template(file: "#{Rails.root}/public/404.html")
    expect(@personal_repository.repository_statuses.count).to eq 0
  end

  it 'should be able to create repository' do
    expect do
      post :create, @create_params
    end.to change(Repository, :count).by(1)
    expect(response).to redirect_to(platform_repository_path(@platform, Repository.last))
  end

  it 'should be able to destroy repository in main platform' do
    expect do
      delete :destroy, id: @repository, platform_id: @platform
    end.to change(Repository, :count).by(-1)
    expect(response).to redirect_to(platform_repositories_path(@repository.platform))
  end

  it 'should be able to perform edit action' do
    get :edit, id: @repository, platform_id: @platform
    expect(response).to render_template(:edit)
  end

  it 'should be able to add new member to repository' do
    post :add_member, id: @repository, platform_id: @platform, member_id: @another_user.id
    expect(response).to redirect_to(edit_platform_repository_path(@repository.platform, @repository))
    expect(@repository.members).to include(@another_user)
  end

  it 'should be able to remove members from repository' do
    another_user2 = FactoryGirl.create(:user)
    create_relation(@repository, @another_user, 'admin')
    create_relation(@repository, another_user2, 'admin')
    post :remove_members, id: @repository, platform_id: @platform,
      members: [@another_user.id, another_user2.id]
    expect(response).to redirect_to(edit_platform_repository_path(@repository.platform, @repository))
    expect(@repository.members).to_not include(@another_user, another_user2)
  end

  it 'should not be able to destroy personal repository with name "main"' do
    # hook for "ActiveRecord::ActiveRecordError: name is marked as readonly"
    Repository.where(id: @personal_repository).update_all("name = 'main'")
    expect do
      delete :destroy, id: @personal_repository, platform_id: @personal_repository.platform
    end.to_not change(Repository, :count)
    # expect(response).to redirect_to(forbidden_path)
    expect(response).to render_template(file: "#{Rails.root}/public/404.html")
  end

  it 'should be able to destroy personal repository with name not "main"' do
    expect do
      delete :destroy, id: @personal_repository, platform_id: @personal_repository.platform
    end.to change(Repository, :count).by(-1)
    expect(response).to redirect_to(platform_repositories_path(@personal_repository.platform))
  end

  it_should_behave_like 'user with change projects in repository rights'
end

describe Platforms::RepositoriesController, type: :controller do
  before(:each) do
    stub_symlink_methods

    @platform = FactoryGirl.create(:platform)
    @repository = FactoryGirl.create(:repository, platform:  @platform)
    @personal_repository = FactoryGirl.create(:personal_repository)
    @project = FactoryGirl.create(:project)
    @another_user = FactoryGirl.create(:user)
    @create_params = {repository: {name: 'pro', description: 'pro2'}, platform_id: @platform}

    @user = FactoryGirl.create(:user)
    set_session_for(@user)
  end

  context 'for guest' do

    before(:each) do
      set_session_for(User.new)
    end

    it_should_behave_like 'registered user' if APP_CONFIG['anonymous_access']

    let(:redirect_path) { new_user_session_path }
    it_should_behave_like 'registered user or guest'
    it_should_behave_like 'user without change projects in repository rights'
    it_should_behave_like 'user without rights of add/remove sync_lock_file to repository'

    it "should not be able to perform show action", anonymous_access: false do
      get :show, id: @repository
      expect(response).to redirect_to(new_user_session_path)
    end

    it "should not be able to perform index action", anonymous_access: false do
      get :index, platform_id: @platform
      expect(response).to redirect_to(new_user_session_path)
    end

    it 'should not be able to perform projects_list action', anonymous_access: false do
      get :projects_list, id: @repository, platform_id: @platform, format: :json
      expect(response.response_code).to eq 401
    end

  end

  context 'for user' do
    it_should_behave_like 'registered user'

    let(:redirect_path) { forbidden_path }
    it_should_behave_like 'registered user or guest'
    it_should_behave_like 'user without change projects in repository rights'
    it_should_behave_like 'user without rights of add/remove sync_lock_file to repository'
  end

  context 'for admin' do
    before(:each) do
      @user.role = "admin"
      @user.save
    end

    it_should_behave_like 'platform admin user'

  end

  context 'for platform owner user' do
    before(:each) do
      @user = @repository.platform.owner
      platform = @personal_repository.platform
      platform.owner = @user
      # Owner of personal platform can't be changed
      platform.save(validate: false)
      set_session_for(@user)
    end

    it_should_behave_like 'platform admin user'
  end

  context 'for platform member user' do
    before(:each) do
      [@repository, @personal_repository].each do |repo|
        create_relation(repo.platform, @user, 'admin')
      end
    end

    it_should_behave_like 'platform admin user'
  end

  context 'for repository member user' do
    before(:each) do
      [@repository, @personal_repository].each do |repo|
        repo.add_member @user
      end
    end

    it_should_behave_like 'registered user'

    let(:redirect_path) { forbidden_path }
    it_should_behave_like 'registered user or guest'
    it_should_behave_like 'user with change projects in repository rights'
    it_should_behave_like 'user without rights of add/remove sync_lock_file to repository'

    context 'for hidden platform' do
      before do
        @platform.update_column(:visibility, 'hidden')
        @personal_repository.platform.update_column(:visibility, 'hidden')
      end
      it_should_behave_like 'registered user'

      let(:redirect_path) { forbidden_path }
      it_should_behave_like 'registered user or guest'
      it_should_behave_like 'user with change projects in repository rights'
      it_should_behave_like 'user without rights of add/remove sync_lock_file to repository'
    end

  end

end
