require 'spec_helper'

def create_pull to_ref, from_ref, owner, project = @project
  pull = project.pull_requests.build issue_attributes: {title: 'test', body: 'testing'}
  pull.issue.user, pull.issue.project = owner, pull.to_project
  pull.to_ref, pull.from_ref, pull.from_project = to_ref, from_ref, project
  pull.save; pull.check
  pull.reload
end

describe Api::V1::PullRequestsController, type: :controller do
  before do
    stub_symlink_methods

    @project = FactoryGirl.create(:project_with_commit)
    @pull = create_pull 'master', 'non_conflicts', @project.owner

    @another_project = FactoryGirl.create(:project_with_commit)
    @another_pull = create_pull 'master', 'non_conflicts', @another_project.owner, @another_project

    @hidden_project = FactoryGirl.create(:project_with_commit)
    @hidden_project.update_column :visibility, 'hidden'
    @hidden_pull = create_pull 'master', 'non_conflicts', @hidden_project.owner, @hidden_project

    @own_hidden_project = FactoryGirl.create(:project_with_commit, owner: @project.owner)
    @own_hidden_project.update_column :visibility, 'hidden'
    @own_hidden_pull = create_pull 'master', 'non_conflicts', @own_hidden_project.owner, @own_hidden_project
    @own_hidden_pull.issue.update_column :assignee_id, @project.owner.id

    @membered_project = FactoryGirl.create(:project_with_commit)
    @membered_pull = create_pull 'master', 'non_conflicts', @membered_project.owner, @membered_project
    create_relation(@membered_project, @pull.user, 'reader')

    @create_params = {pull_request: {title: 'title', body: 'body',
                                        from_ref: 'conflicts', to_ref: 'master'},
                      project_id: @project.id, format: :json}

    @update_params = {pull_request: {title: 'new title'},
                      project_id: @project.id, id: @pull.serial_id, format: :json}

    @issue = FactoryGirl.create(:issue, project: @project)
  end

  context 'read and accessible abilities' do
    context 'for user' do
      before do
        http_login(@project.owner)
      end

      it 'can show pull request in own project' do
        get :show, project_id: @project.id, id: @pull.serial_id, format: :json
        expect(response).to be_success
      end

      it 'should render right template for show action' do
        get :show, project_id: @project.id, id: @pull.serial_id, format: :json
        expect(response).to render_template('api/v1/pull_requests/show')
      end

      it 'can show pull request in open project' do
        get :show, project_id: @another_project.id, id: @another_pull.serial_id, format: :json
        expect(response).to be_success
      end

      it 'can show pull request in own hidden project' do
        get :show, project_id: @own_hidden_project.id, id: @own_hidden_pull.serial_id, format: :json
        expect(response).to be_success
      end

      it 'cant show pull request in hidden project' do
        get :show, project_id: @hidden_project.id, id: @hidden_pull.serial_id, format: :json
        expect(response.status).to eq 403
      end

      it 'should return three pull requests' do
        get :all_index, filter: 'all', format: :json
        expect(assigns[:pulls]).to include(@pull)
        expect(assigns[:pulls]).to include(@own_hidden_pull)
        expect(assigns[:pulls]).to include(@membered_pull)
      end

      it 'should render right template for all index action' do
        get :all_index, format: :json
        expect(response).to render_template('api/v1/pull_requests/index')
      end

      it 'should return only assigned pull request' do
        get :user_index, format: :json
        expect(assigns[:pulls]).to include(@own_hidden_pull)
        expect(assigns[:pulls].count).to eq 1
      end

      it 'should render right template for user index action' do
        get :user_index, format: :json
        expect(response).to render_template('api/v1/pull_requests/index')
      end

      %w(commits files).each do |action|
        it "can show pull request #{action} in own project" do
          get action, project_id: @project.id, id: @pull.serial_id, format: :json
          expect(response).to be_success
        end

        it "should render right template for commits action" do
          get action, project_id: @project.id, id: @pull.serial_id, format: :json
          expect(response).to render_template("api/v1/pull_requests/#{action}")
        end

        it "can't show pull request #{action} in hidden project" do
          get action, project_id: @hidden_project.id, id: @hidden_pull.serial_id, format: :json
          expect(response).to_not be_success
        end
      end

      it 'should return 404' do
        get :show, project_id: @project.id, id: 999999, format: :json
        expect(response.status).to eq 404
      end

      it 'should redirect to issue page' do
        get :show, project_id: @project.id, id: @issue.serial_id, format: :json
        expect(response).to redirect_to(api_v1_project_issue_path(@project.id, @issue.serial_id))
      end
    end

    context 'for anonymous user' do
      it 'can show pull request in open project', anonymous_access: true do
        get :show, project_id: @project.id, id: @pull.serial_id, format: :json
        expect(response).to be_success
      end

      it 'cant show pull request in hidden project', anonymous_access: true do
        @project.update_column :visibility, 'hidden'
        get :show, project_id: @project.id, id: @pull.serial_id, format: :json
        expect(response.status).to eq 403
      end

      it 'should not return any pull requests' do
        get :all_index, filter: 'all', format: :json
        expect(response.status).to eq 401
      end

      %w(commits files).each do |action|
        it "can show pull request #{action} in project", anonymous_access: true do
          get action, project_id: @project.id, id: @pull.serial_id, format: :json
          expect(response).to be_success
        end

        it "should render right template for commits action", anonymous_access: true do
          get action, project_id: @project.id, id: @pull.serial_id, format: :json
          expect(response).to render_template("api/v1/pull_requests/#{action}")
        end

        it "can't show pull request #{action} in hidden project", anonymous_access: true do
          get action, project_id: @hidden_project.id, id: @hidden_pull.serial_id, format: :json
          expect(response).to_not be_success
        end
      end
    end
  end

  context 'create accessibility' do
    context 'for user' do
      before(:each) do
        http_login(@pull.user)
      end

      it 'can create pull request in own project' do
        expect do
          post :create, @create_params
        end.to change(PullRequest, :count).by(1)
      end

      it 'can create pull request in own hidden project' do
        expect do
          post :create, @create_params.merge(project_id: @own_hidden_project.id)
        end.to change(PullRequest, :count).by(1)
      end

      it 'can create pull request in open project' do
        expect do
          post :create, @create_params.merge(project_id: @another_project.id)
        end.to change(PullRequest, :count).by(1)
      end

      it 'cant create pull request in hidden project' do
        expect do
          post :create, @create_params.merge(project_id: @hidden_project.id)
        end.to_not change(PullRequest, :count)
      end
    end

    context 'for anonymous user' do
      it 'cant create pull request in project', anonymous_access: true do
        expect do
          post :create, @create_params
        end.to_not change(PullRequest, :count)
      end

      it 'cant create pull request in hidden project', anonymous_access: true do
        expect do
          post :create, @create_params.merge(project_id: @hidden_project.id)
        end.to_not change(PullRequest, :count)
      end
    end
  end

  context 'update accessibility' do
    context 'for user' do
      before(:each) do
        http_login(@project.owner)
      end

      it 'can update pull request in own project' do
        put :update, @update_params
        expect(@pull.reload.title).to eq 'new title'
      end

      it 'can update pull request in own hidden project' do
        put :update, @update_params.merge(project_id: @own_hidden_project.id, id: @own_hidden_pull.serial_id)
        expect(@own_hidden_pull.reload.title).to eq 'new title'
      end

      it 'cant update pull request in open project' do
        put :update, @update_params.merge(project_id: @another_project.id, id: @another_pull.serial_id)
        expect(@another_pull.reload.title).to_not eq 'new title'
      end

      it 'cant update pull request in hidden project' do
        put :update, @update_params.merge(project_id: @hidden_project.id, id: @hidden_pull.serial_id)
        expect(@hidden_pull.reload.title).to_not eq 'title'
      end

      it 'can merge pull request in own project' do
        put :merge, project_id: @project.id, id: @pull.serial_id, format: :json
        expect(@pull.reload.status).to eq 'merged'
        expect(response).to be_success
      end

      it 'can merge pull request in own hidden project' do
        put :merge, project_id: @own_hidden_project.id, id: @own_hidden_pull.serial_id, format: :json
        expect(@own_hidden_pull.reload.status).to eq 'merged'
        expect(response).to be_success
      end

      it 'cant merge pull request in open project' do
        put :merge, project_id: @another_project.id, id: @another_pull.serial_id, format: :json
        expect(@another_pull.reload.status).to eq 'ready'
        expect(response.status).to eq 403
      end

      it 'cant merge pull request in hidden project' do
        put :merge, project_id: @hidden_project.id, id: @hidden_pull.serial_id, format: :json
        expect(@hidden_pull.reload.status).to eq 'ready'
        expect(response.status).to eq 403
      end
    end

    context 'for anonymous user' do
      it 'cant update pull request in project', anonymous_access: true do
        put :update, @update_params
        expect(response.status).to eq 401
      end

      it 'cant update pull request in hidden project', anonymous_access: true do
        put :update, @update_params.merge(project_id: @hidden_project.id, id: @hidden_pull.serial_id)
        expect(response.status).to eq 401
      end

      it 'cant merge pull request in open project' do
        put :merge, project_id: @another_project.id, id: @another_pull.serial_id, format: :json
        expect(@another_pull.reload.status).to eq 'ready'
        expect(response.status).to eq 401
      end

      it 'cant merge pull request in hidden project' do
        put :merge, project_id: @hidden_project.id, id: @hidden_pull.serial_id, format: :json
        expect(@hidden_pull.reload.status).to eq 'ready'
        expect(response.status).to eq 401
      end
    end
  end

  context 'send email messages' do
    before do
      @project_reader = FactoryGirl.create :user
      create_relation(@project, @project_reader, 'reader')
      @project_admin = FactoryGirl.create :user
      create_relation(@project, @project_admin, 'admin')
      @project_writer = FactoryGirl.create :user
      create_relation(@project, @project_writer, 'writer')

      http_login(@project_writer)
      ActionMailer::Base.deliveries = []
    end

    it 'should send two email messages to all project members' do
      post :create, @create_params
      expect(ActionMailer::Base.deliveries.count).to eq 3 # project owner + reader + admin
    end

    it 'should send two email messages to admins and one to assignee' do
      post :create, @create_params.deep_merge(pull_request: {assignee_id: @project_reader.id})
      expect(ActionMailer::Base.deliveries.count).to eq 3
    end

    it 'should send email message to new assignee' do
      http_login(@project_admin)
      put :update, @update_params.deep_merge(pull_request: {assignee_id: @project_reader.id})
      expect(ActionMailer::Base.deliveries.count).to eq 1
    end

    it 'should not duplicate email message' do
      post :create, @create_params.deep_merge(pull_request: {assignee_id: @project_admin.id})
      expect(ActionMailer::Base.deliveries.count).to eq 3 # send to all project members
      expect(ActionMailer::Base.deliveries.map(&:to).uniq).to match_array(ActionMailer::Base.deliveries.map(&:to))
    end
  end

end
