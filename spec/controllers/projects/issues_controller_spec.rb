require 'spec_helper'

shared_context "issues controller" do
  before do
    stub_symlink_methods

    @project = FactoryGirl.create(:project_with_commit)
    @issue_user = FactoryGirl.create(:user)

    @issue = FactoryGirl.create(:issue, project_id: @project.id, assignee_id: @issue_user.id)
    @label = FactoryGirl.create(:label, project_id: @project.id)

    @project_with_turned_off_issues = FactoryGirl.create(:project, has_issues: false)
    @turned_of_issue = FactoryGirl.create(:issue, project_id: @project_with_turned_off_issues.id, assignee_id: @issue_user.id)

    @user = FactoryGirl.create(:user)
    set_session_for(@user)

    @create_params = {
      name_with_owner: @project.name_with_owner,
      issue: {
        title: "issue1",
        body: "issue body",
        labelings_attributes: { @label.id.to_s => { label_id: @label.id }},
        assignee_id: @issue_user.id
      }
    }

    @update_params = { name_with_owner: @project.name_with_owner, issue: { title: "issue2" }, format: :json }

    @pull = create_pull_request(@project)
  end

end

shared_examples_for 'issue user with project guest rights' do
  it 'should be able to perform index action' do
    get :index, name_with_owner: @project.name_with_owner
    expect(response).to render_template(:index)
  end

  it 'should be able to perform show action' do
    get :show, name_with_owner: @project.name_with_owner, id: @issue.serial_id
    expect(response).to render_template(:show)
  end
end

shared_examples_for 'issue user with project reader rights' do

  it 'should be able to perform index action on hidden project' do
    @project.update_attributes(visibility: 'hidden')
    get :index, name_with_owner: @project.name_with_owner
    expect(response).to render_template(:index)
  end

  it 'should be able to perform create action' do
    post :create, @create_params
    expect(response).to redirect_to(project_issues_path(@project))
  end

  it 'should create issue object into db' do
    expect do
      post :create, @create_params
    end.to change(Issue, :count).by(1)
  end
end

shared_examples_for 'issue user with project writer rights' do
  it 'should be able to perform index action on hidden project' do
    @project.update_attributes(visibility: 'hidden')
    get :index, name_with_owner: @project.name_with_owner
    expect(response).to render_template(:index)
  end

  it 'should create issue object into db' do
    expect do
      post :create, @create_params
    end.to change(Issue, :count).by(1)
  end

  context 'perform create action' do
    before { post :create, @create_params }

    it 'user should be assigned to issue' do
      expect(@project.issues.last.assignee_id).to_not be_nil
    end

    it 'label should be attached to issue' do
      expect(@project.issues.last.labels.count).to eq 1
    end
  end
end

shared_examples_for 'user with issue update rights' do
  it 'should be able to perform update action' do
    put :update, {id: @issue.serial_id}.merge(@update_params)
    expect(response).to be_success
  end

  it 'should update issue title' do
    put :update, {id: @issue.serial_id}.merge(@update_params)
    expect(@issue.reload.title).to eq 'issue2'
  end
end

shared_examples_for 'user without issue update rights' do
  it 'should not be able to perform update action' do
    put :update, {id: @issue.serial_id}.merge(@update_params)
    expect(response).to redirect_to(forbidden_path)
  end

  it 'should not update issue title' do
    put :update, {id: @issue.serial_id}.merge(@update_params)
    expect(@issue.reload.title).to_not eq 'issue2'
  end
end

# shared_examples_for 'user without issue destroy rights' do
#   it 'should not be able to perform destroy action' do
#     delete :destroy, id: @issue.serial_id, name_with_owner: @project.name_with_owner
#     expect(response).to redirect_to(controller.current_user ? forbidden_path : new_user_session_path)
#   end

#   it 'should not reduce issues count' do
#     expect
#       delete :destroy, id: @issue.serial_id, name_with_owner: @project.name_with_owner
#     end.to change(Issue, :count).by(0)
#   end
# end

shared_examples_for 'project with issues turned off' do
  it 'should not be able to perform index action' do
    get :index, name_with_owner: @project_with_turned_off_issues.name_with_owner
    expect(response).to redirect_to(forbidden_path)
  end

  it 'should not be able to perform show action' do
    get :show, name_with_owner: @project_with_turned_off_issues.name_with_owner, id: @turned_of_issue.serial_id
    expect(response).to redirect_to(forbidden_path)
  end
end

describe Projects::IssuesController, type: :controller do
  include_context "issues controller"

  context 'for global admin user' do
    before do
      @user.role = "admin"
      @user.save
    end

    it_should_behave_like 'issue user with project guest rights'
    it_should_behave_like 'issue user with project reader rights'
    it_should_behave_like 'issue user with project writer rights'
    it_should_behave_like 'user with issue update rights'
    it_should_behave_like 'project with issues turned off'
    # it_should_behave_like 'user without issue destroy rights'
  end

  context 'for project admin user' do
    before do
      create_relation(@project, @user, 'admin')
    end

    it_should_behave_like 'issue user with project guest rights'
    it_should_behave_like 'issue user with project reader rights'
    it_should_behave_like 'issue user with project writer rights'
    it_should_behave_like 'user with issue update rights'
    it_should_behave_like 'project with issues turned off'
    # it_should_behave_like 'user without issue destroy rights'
  end

  context 'for project owner user' do
    before do
      @user = @project.owner
      set_session_for(@user)
    end

    it_should_behave_like 'issue user with project guest rights'
    it_should_behave_like 'issue user with project reader rights'
    it_should_behave_like 'issue user with project writer rights'
    it_should_behave_like 'user with issue update rights'
    it_should_behave_like 'project with issues turned off'
    # it_should_behave_like 'user without issue destroy rights'
  end

  context 'for project reader user' do
    before do
      create_relation(@project, @user, 'reader')
    end

    it_should_behave_like 'issue user with project guest rights'
    it_should_behave_like 'issue user with project reader rights'
    it_should_behave_like 'user without issue update rights'
    it_should_behave_like 'project with issues turned off'
    # it_should_behave_like 'user without issue destroy rights'

    context 'perform create action' do
      before { post :create, @create_params }

      it 'user should not be assigned to issue' do
        expect(@project.issues.last.assignee_id).to be_nil
      end

      it 'label should not be attached to issue' do
        expect(@project.issues.last.labels.count).to eq 0
      end
    end

    it 'should return 404' do
      get :show, name_with_owner: @project.name_with_owner, id: 999999
      expect(response).to render_template(file: "#{Rails.root}/public/404.html")
    end

    it 'should redirect to pull request page' do
      get :show, name_with_owner: @project.name_with_owner, id: @pull.reload.serial_id
      expect(response).to redirect_to(project_pull_request_path(@project, @pull))
    end

    it 'should redirect to pull request in project with turned off issues' do
      @project.update_attribute :has_issues, false
      get :show, name_with_owner: @project.name_with_owner, id: @pull.reload.serial_id
      expect(response).to redirect_to(project_pull_request_path(@project, @pull))
    end

  end

  context 'for project writer user' do
    before do
      create_relation(@project, @user, 'writer')
    end

    it_should_behave_like 'issue user with project guest rights'
    it_should_behave_like 'issue user with project reader rights'
    it_should_behave_like 'issue user with project writer rights'
    it_should_behave_like 'user without issue update rights'
    it_should_behave_like 'project with issues turned off'
    # it_should_behave_like 'user without issue destroy rights'
  end

  context 'for issue assign user' do
    before do
      set_session_for(@issue_user)
    end

    it_should_behave_like 'user without issue update rights'
    it_should_behave_like 'project with issues turned off'
    # it_should_behave_like 'user without issue destroy rights'
  end

  context 'for guest' do

    before do
      set_session_for(User.new)
    end

    if APP_CONFIG['anonymous_access']

      it_should_behave_like 'issue user with project guest rights'

      it 'should not be able to perform index action on hidden project' do
        @project.update_attributes(visibility: 'hidden')
        get :index, name_with_owner: @project.name_with_owner
        expect(response).to redirect_to(forbidden_path)
      end

    else
      it 'should not be able to perform index action' do
        get :index, name_with_owner: @project.name_with_owner
        expect(response).to redirect_to(new_user_session_path)
      end

      it 'should not be able to perform show action' do
        get :show, name_with_owner: @project.name_with_owner, id: @issue.serial_id
        expect(response).to redirect_to(new_user_session_path)
      end

      it 'should not be able to perform index action on hidden project' do
        @project.update_attributes(visibility: 'hidden')
        get :index, name_with_owner: @project.name_with_owner
        expect(response).to redirect_to(new_user_session_path)
      end
    end

    it 'should not be able to perform create action' do
      post :create, @create_params
      expect(response).to redirect_to(new_user_session_path)
    end

    it 'should not create issue object into db' do
      expect do
        post :create, @create_params
      end.to change(Issue, :count).by(0)
    end

    #it_should_behave_like 'user without issue update rights'
    it 'should not be able to perform update action' do
      put :update, {id: @issue.serial_id}.merge(@update_params)
      expect(response.code).to eq '401'
    end

    it 'should not update issue title' do
      put :update, {id: @issue.serial_id}.merge(@update_params)
      expect(@issue.reload.title).to_not eq 'issue2'
    end

    # it_should_behave_like 'user without issue destroy rights'
  end
end
