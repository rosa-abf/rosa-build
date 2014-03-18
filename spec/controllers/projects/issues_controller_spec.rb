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
      owner_name: @project.owner.uname, project_name: @project.name,
      issue: {
        title: "issue1",
        body: "issue body",
        labelings_attributes: { @label.id => {label_id: @label.id}},
        assignee_id: @issue_user.id
      }
    }

    @update_params = {
      owner_name: @project.owner.uname, project_name: @project.name,
      issue: {
        title: "issue2"
      }
    }

    @pull = @project.pull_requests.new issue_attributes: {title: 'test', body: 'testing'}
    @pull.issue.user, @pull.issue.project = @project.owner, @pull.to_project
    @pull.to_ref = 'master'
    @pull.from_project, @pull.from_ref = @project, 'non_conflicts'
    @pull.save
  end

end

shared_examples_for 'issue user with project guest rights' do
  it 'should be able to perform index action' do
    get :index, owner_name: @project.owner.uname, project_name: @project.name
    response.should render_template(:index)
  end

  it 'should be able to perform show action' do
    get :show, owner_name: @project.owner.uname, project_name: @project.name, id: @issue.serial_id
    response.should render_template(:show)
  end
end

shared_examples_for 'issue user with project reader rights' do

  it 'should be able to perform index action on hidden project' do
    @project.update_attributes(visibility: 'hidden')
    get :index, owner_name: @project.owner.uname, project_name: @project.name
    response.should render_template(:index)
  end

  it 'should be able to perform create action' do
    post :create, @create_params
    response.should redirect_to(project_issues_path(@project))
  end

  it 'should create issue object into db' do
    lambda{ post :create, @create_params }.should change{ Issue.count }.by(1)
  end
end

shared_examples_for 'issue user with project writer rights' do
  it 'should be able to perform index action on hidden project' do
    @project.update_attributes(visibility: 'hidden')
    get :index, owner_name: @project.owner.uname, project_name: @project.name
    response.should render_template(:index)
  end

  it 'should create issue object into db' do
    lambda{ post :create, @create_params }.should change{ Issue.count }.by(1)
  end

  context 'perform create action' do
    before { post :create, @create_params }

    it 'user should be assigned to issue' do
      @project.issues.last.assignee_id.should_not be_nil
    end

    it 'label should be attached to issue' do
      @project.issues.last.labels.should have(1).item
    end
  end
end

shared_examples_for 'user with issue update rights' do
  it 'should be able to perform update action' do
    put :update, {id: @issue.serial_id}.merge(@update_params)
    response.code.should eq('200')
  end

  it 'should update issue title' do
    put :update, {id: @issue.serial_id}.merge(@update_params)
    @issue.reload.title.should == 'issue2'
  end
end

shared_examples_for 'user without issue update rights' do
  it 'should not be able to perform update action' do
    put :update, {id: @issue.serial_id}.merge(@update_params)
    response.should redirect_to(controller.current_user ? forbidden_path : new_user_session_path)
  end

  it 'should not update issue title' do
    put :update, {id: @issue.serial_id}.merge(@update_params)
    @issue.reload.title.should_not == 'issue2'
  end
end

shared_examples_for 'user without issue destroy rights' do
  it 'should not be able to perform destroy action' do
    delete :destroy, id: @issue.serial_id, owner_name: @project.owner.uname, project_name: @project.name
    response.should redirect_to(controller.current_user ? forbidden_path : new_user_session_path)
  end

  it 'should not reduce issues count' do
    lambda{ delete :destroy, id: @issue.serial_id, owner_name: @project.owner.uname, project_name: @project.name }.should_not change{ Issue.count }
  end
end

shared_examples_for 'project with issues turned off' do
  it 'should not be able to perform index action' do
    get :index, owner_name: @project_with_turned_off_issues.owner.uname, project_name: @project_with_turned_off_issues.name
    response.should redirect_to(forbidden_path)
  end

  it 'should not be able to perform show action' do
    get :show, owner_name: @project_with_turned_off_issues.owner.uname, project_name: @project_with_turned_off_issues.name, id: @turned_of_issue.serial_id
    response.should redirect_to(forbidden_path)
  end
end

describe Projects::IssuesController do
  include_context "issues controller"

  context 'for global admin user' do
    before(:each) do
      @user.role = "admin"
      @user.save
    end

    it_should_behave_like 'issue user with project guest rights'
    it_should_behave_like 'issue user with project reader rights'
    it_should_behave_like 'issue user with project writer rights'
    it_should_behave_like 'user with issue update rights'
    it_should_behave_like 'project with issues turned off'
    it_should_behave_like 'user without issue destroy rights'
  end

  context 'for project admin user' do
    before(:each) do
      create_relation(@project, @user, 'admin')
    end

    it_should_behave_like 'issue user with project guest rights'
    it_should_behave_like 'issue user with project reader rights'
    it_should_behave_like 'issue user with project writer rights'
    it_should_behave_like 'user with issue update rights'
    it_should_behave_like 'project with issues turned off'
    it_should_behave_like 'user without issue destroy rights'
  end

  context 'for project owner user' do
    before(:each) do
      @user = @project.owner
      set_session_for(@user)
    end

    it_should_behave_like 'issue user with project guest rights'
    it_should_behave_like 'issue user with project reader rights'
    it_should_behave_like 'issue user with project writer rights'
    it_should_behave_like 'user with issue update rights'
    it_should_behave_like 'project with issues turned off'
    it_should_behave_like 'user without issue destroy rights'
  end

  context 'for project reader user' do
    before(:each) do
      create_relation(@project, @user, 'reader')
    end

    it_should_behave_like 'issue user with project guest rights'
    it_should_behave_like 'issue user with project reader rights'
    it_should_behave_like 'user without issue update rights'
    it_should_behave_like 'project with issues turned off'
    it_should_behave_like 'user without issue destroy rights'

    context 'perform create action' do
      before { post :create, @create_params }

      it 'user should not be assigned to issue' do
        @project.issues.last.assignee_id.should be_nil
      end

      it 'label should not be attached to issue' do
        @project.issues.last.labels.should have(:no).items
      end
    end

    # it 'should not be able to perform create action on project' do
    #   post :create, @create_params
    #   response.should redirect_to(forbidden_path)
    # end

    # it 'should not create issue object into db' do
    #   lambda{ post :create, @create_params }.should change{ Issue.count }.by(0)
    # end

    it 'should return 404' do
      get :show, owner_name: @project.owner.uname, project_name: @project.name, id: 999999
      render_template(file: "#{Rails.root}/public/404.html")
    end

    it 'should redirect to pull request page' do
      get :show, owner_name: @project.owner.uname, project_name: @project.name, id: @pull.serial_id
      response.should redirect_to(project_pull_request_path(@project, @pull))
    end
  end

  context 'for project writer user' do
    before(:each) do
      create_relation(@project, @user, 'writer')
    end

    it_should_behave_like 'issue user with project guest rights'
    it_should_behave_like 'issue user with project reader rights'
    it_should_behave_like 'issue user with project writer rights'
    it_should_behave_like 'user without issue update rights'
    it_should_behave_like 'project with issues turned off'
    it_should_behave_like 'user without issue destroy rights'
  end

  context 'for issue assign user' do
    before(:each) do
      set_session_for(@issue_user)
    end

    it_should_behave_like 'user without issue update rights'
    it_should_behave_like 'project with issues turned off'
    it_should_behave_like 'user without issue destroy rights'
  end

  context 'for guest' do

    before(:each) do
      set_session_for(User.new)
    end

    if APP_CONFIG['anonymous_access']

      it_should_behave_like 'issue user with project guest rights'

      it 'should not be able to perform index action on hidden project' do
        @project.update_attributes(visibility: 'hidden')
        get :index, owner_name: @project.owner.uname, project_name: @project.name
        response.should redirect_to(forbidden_path)
      end

    else
      it 'should not be able to perform index action' do
        get :index, owner_name: @project.owner.uname, project_name: @project.name
        response.should redirect_to(new_user_session_path)
      end

      it 'should not be able to perform show action' do
        get :show, owner_name: @project.owner.uname, project_name: @project.name, id: @issue.serial_id
        response.should redirect_to(new_user_session_path)
      end

      it 'should not be able to perform index action on hidden project' do
        @project.update_attributes(visibility: 'hidden')
        get :index, owner_name: @project.owner.uname, project_name: @project.name
        response.should redirect_to(new_user_session_path)
      end
    end

    it 'should not be able to perform create action' do
      post :create, @create_params
      response.should redirect_to(new_user_session_path)
    end

    it 'should not create issue object into db' do
      lambda{ post :create, @create_params }.should_not change{ Issue.count }
    end

    it_should_behave_like 'user without issue update rights'
    it_should_behave_like 'user without issue destroy rights'
  end
end
