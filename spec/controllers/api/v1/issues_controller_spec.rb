require 'spec_helper'

describe Api::V1::IssuesController, type: :controller do
  let(:user)          { FactoryGirl.create(:user) }
  let(:project)       { FactoryGirl.create(:project_with_commit) }
  let(:issue)         { FactoryGirl.create(:issue, project: project, user: user) }
  let(:open_project)  { FactoryGirl.create(:project) }
  let(:open_issue)    { FactoryGirl.create(:issue, project: open_project) }
  let(:own_hidden_project)  { FactoryGirl.create(:project, owner: user, visibility: 'hidden') }
  let(:own_hidden_issue)    { FactoryGirl.create(:issue, project: own_hidden_project, assignee: user) }
  let(:hidden_project)      { FactoryGirl.create(:project, visibility: 'hidden') }
  let(:hidden_issue)        { FactoryGirl.create(:issue, project: hidden_project) }
  let(:create_params)       { {issue: {title: 'title', body: 'body'}, project_id: project.id, format: :json} }
  let(:update_params)       { {issue: {title: 'new title'}, project_id: project.id, id: issue.serial_id, format: :json} }

  before do
    stub_symlink_methods
    allow_any_instance_of(Project).to receive(:versions).and_return(%w(v1.0 v2.0))
  end

  context 'read and accessible abilities' do
    context 'for user' do
      before do
        http_login(user)
      end

      it 'can show issue in own project' do
        get :show, project_id: project.id, id: issue.serial_id, format: :json
        expect(response).to be_success
      end

      it 'should render right template for show action' do
        get :show, project_id: project.id, id: issue.serial_id, format: :json
        expect(response).to render_template('api/v1/issues/show')
      end

      it 'can show issue in open project' do
        get :show, project_id: open_project.id, id: open_issue.serial_id, format: :json
        expect(response).to be_success
      end

      it 'can show issue in own hidden project' do
        get :show, project_id: own_hidden_project.id, id: own_hidden_issue.serial_id, format: :json
        expect(response).to be_success
      end

      it "can't show issue in hidden project" do
        get :show, project_id: hidden_project.id, id: hidden_issue.serial_id, format: :json
        expect(response.code).to eq '403'
      end

      it 'should return three issues' do
        membered_issue = FactoryGirl.create(:issue)
        membered_project = membered_issue.project
        create_relation(membered_project, issue.user, 'reader')

        issue && own_hidden_issue # init
        get :all_index, filter: 'all', format: :json
        expect(assigns[:issues]).to include(issue)
        expect(assigns[:issues]).to include(own_hidden_issue)
        expect(assigns[:issues]).to include(membered_issue)
      end

      it 'should render right template for all index action' do
        get :all_index, format: :json
        expect(response).to render_template('api/v1/issues/index')
      end

      it 'should return only assigned issue' do
        own_hidden_issue # init
        get :user_index, format: :json
        expect(assigns[:issues]).to include(own_hidden_issue)
        expect(assigns[:issues].count).to eq 1
      end

      it 'should render right template for user index action' do
        get :user_index, format: :json
        expect(response).to render_template('api/v1/issues/index')
      end

      it 'should return 404' do
        get :show, project_id: project.id, id: 999999, format: :json
        expect(response.code).to eq '404'
      end

      it 'should redirect to pull request page' do
        pull = project.pull_requests.new issue_attributes: {title: 'test', body: 'testing'}
        pull.issue.user, pull.issue.project = project.owner, pull.to_project
        pull.to_ref = 'master'
        pull.from_project, pull.from_ref = project, 'non_conflicts'
        pull.save

        get :show, project_id: project.id, id: pull.reload.serial_id, format: :json
        expect(response).to redirect_to(api_v1_project_pull_request_path(project.id, pull.serial_id))
      end
    end

    context 'for anonymous user' do
      it 'can show issue in open project', anonymous_access: true do
        get :show, project_id: project.id, id: issue.serial_id, format: :json
        expect(response).to be_success
      end

      it "can't show issue in hidden project", anonymous_access: true do
        get :show, project_id: hidden_project.id, id: hidden_issue.serial_id, format: :json
        expect(response.code).to eq '403'
      end

      it 'should not return any issues' do
        get :all_index, filter: 'all', format: :json
        expect(response.code).to eq '401'
      end
    end
  end

  context 'create accessibility' do
    context 'for user' do
      before do
        http_login(user)
      end

      it 'can create issue in own project' do
        expect do
          post :create, create_params
        end.to change(Issue, :count).by(1)
      end

      it 'can create issue in own hidden project' do
        expect do
          post :create, create_params.merge(project_id: own_hidden_project.id)
        end.to change(Issue, :count).by(1)
      end

      it 'can create issue in open project' do
        expect do
          post :create, create_params.merge(project_id: open_project.id)
        end.to change(Issue, :count).by(1)
      end

      it "can't create issue in hidden project" do
        expect do
          post :create, create_params.merge(project_id: hidden_project.id)
        end.to change(Issue, :count).by(0)
      end

      it 'can assignee issue in own project' do
        post :create, create_params.deep_merge(project_id: own_hidden_project.id, issue: {assignee_id: user.id})
        expect(own_hidden_project.issues.order(:id).last.assignee.id).to eq user.id
      end

      it "can't assignee issue in open project" do
        post :create, create_params.deep_merge(project_id: open_project.id, issue: {assignee_id: user.id})
        expect(open_project.issues.order(:id).last.assignee).to be_nil
      end
    end

    context 'for anonymous user' do
      it "can't create issue in project", anonymous_access: true do
        expect do
          post :create, create_params
        end.to change(Issue, :count).by(0)
      end

      it "can't create issue in hidden project", anonymous_access: true do
        expect do
          post :create, create_params.merge(project_id: hidden_project.id)
        end.to change(Issue, :count).by(0)
      end
    end
  end

  context 'update accessibility' do
    context 'for user' do
      before(:each) do
        http_login(user)
      end

      it 'can update issue in own project' do
        put :update, update_params
        expect(issue.reload.title).to eq 'new title'
      end

      it 'can update issue in own hidden project' do
        put :update, update_params.merge(project_id: own_hidden_project.id, id: own_hidden_issue.serial_id)
        expect(own_hidden_issue.reload.title).to eq 'new title'
      end

      it "can't update issue in open project" do
        put :update, update_params.merge(project_id: open_project.id, id: open_issue.serial_id)
        expect(open_issue.reload.title).to_not eq 'new title'
      end

      it "can't update issue in hidden project" do
        put :update, update_params.merge(project_id: hidden_project.id, id: hidden_issue.serial_id)
        expect(hidden_issue.reload.title).to_not eq 'title'
      end

      it "can't assignee issue in open project" do
        post :create, update_params.deep_merge(project_id: open_project.id, issue: {assignee_id: user.id})
        expect(open_issue.reload.assignee.id).to_not eq issue.user.id
      end

      it 'can assignee issue in own project' do
        post :create, update_params.deep_merge(issue: {assignee_id: issue.user.id})
        expect(issue.reload.assignee.id).to_not eq issue.user.id
      end
    end

    context 'for anonymous user' do
      it "can't update issue in project", anonymous_access: true do
        put :update, update_params
        expect(response.code).to eq '401'
      end

      it "can't update issue in hidden project", anonymous_access: true do
        put :update, update_params.merge(project_id: hidden_project.id, id: hidden_issue.serial_id)
        expect(response.code).to eq '401'
      end
    end
  end

end
