require 'spec_helper'

shared_context "pull request controller" do
  after { FileUtils.rm_rf File.join(Rails.root, "tmp", Rails.env, "pull_requests") }
  before do
    FileUtils.rm_rf(APP_CONFIG['root_path'])
    stub_symlink_methods

    @project = FactoryGirl.create(:project_with_commit)

    @pull = @project.pull_requests.new issue_attributes: {title: 'test', body: 'testing'}
    @pull.issue.user, @pull.issue.project = @project.owner, @pull.to_project
    @pull.to_ref = 'master'
    @pull.from_project, @pull.from_ref = @project, 'non_conflicts'
    @pull.save

    @create_params = {
      pull_request: { issue_attributes: { title: 'create', body: 'creating' },
                                to_ref: 'non_conflicts',
                              from_ref: 'master' },
      to_project: @project.name_with_owner,
      name_with_owner: @project.name_with_owner
    }
    @update_params = @create_params.merge(pull_request_action: 'close', id: @pull.serial_id)
    @wrong_update_params = @create_params.merge(
      pull_request: { issue_attributes: { title: 'update', body: 'updating', id: @pull.issue.id }},
      id: @pull.serial_id
    )

    @user = FactoryGirl.create(:user)
    set_session_for(@user)

    @issue = FactoryGirl.create(:issue, project: @project)
  end
end

shared_examples_for 'pull request user with project guest rights' do
  it 'should be able to perform index action' do
    get :index, name_with_owner: @project.name_with_owner
    response.should render_template(:index)
  end

  it 'should be able to perform show action when pull request has been created' do
    @pull.check
    get :show, name_with_owner: @project.name_with_owner, id: @pull.serial_id
    response.should render_template(:show)
  end
end

shared_examples_for 'pull request user with project reader rights' do
  it 'should be able to perform index action on hidden project' do
    @project.update_attributes(visibility: 'hidden')
    get :index, name_with_owner: @project.name_with_owner
    response.should render_template(:index)
  end

  it 'should be able to perform create action' do
    post :create, @create_params
    response.should redirect_to(project_pull_request_path(@project, @project.pull_requests.last))
  end

  it 'should create pull request object into db' do
    lambda{ post :create, @create_params }.should change{ PullRequest.joins(:issue).
      where(issues: {title: 'create', body: 'creating'}).count }.by(1)
  end

  it "should not create same pull" do
    post :create, @create_params.merge({pull_request: {issue_attributes: {title: 'same', body: 'creating'}, from_ref: 'non_conflicts', to_ref: 'master'}, to_project_id: @project.id})
    PullRequest.joins(:issue).where(issues: {title: 'same', body: 'creating'}).count.should == 0
  end

  it "should not create already up-to-date pull" do
    post :create, @create_params.merge({pull_request: {issue_attributes: {title: 'already', body: 'creating'}, to_ref: 'master', from_ref: 'master'}, to_project_id: @project.id})
    PullRequest.joins(:issue).where(issues: {title: 'already', body: 'creating'}).count.should == 0
  end

  it "should create pull request to the same project" do
    @parent = FactoryGirl.create(:project)
    @project.update_attributes({parent_id: @parent}, without_protection: true)

    lambda{ post :create, @create_params }.should change{ PullRequest.joins(:issue).
      where(issues: {user_id: @user}, to_project_id: @project, from_project_id: @project).count }.by(1)
  end

  it "should create pull request to the parent project" do
    @parent = FactoryGirl.create(:project_with_commit)
    @project.update_attributes({parent_id: @parent}, without_protection: true)

    lambda{ post :create, @create_params.merge({to_project: @parent.name_with_owner}) }.should change{ PullRequest.joins(:issue).
      where(issues: {user_id: @user}, to_project_id: @parent, from_project_id: @project).count }.by(1)
  end
end

shared_examples_for 'user with pull request update rights' do
  it 'should be able to perform update action' do
    put :update, @update_params
    response.should be_success
  end

  it 'should be able to perform merge action' do
    @pull.check
    put :merge, @update_params
    response.should be_success
  end

  let(:pull) { @project.pull_requests.find(@pull) }
  it 'should update pull request status' do
    put :update, @update_params
    pull.status.should =='closed'
  end

  it 'should not update pull request title' do
    put :update, @wrong_update_params
    pull.issue.title.should =='test'
  end

  it 'should not update pull request body' do
    put :update, @wrong_update_params
    pull.issue.body.should =='testing'
  end

  it 'should not update pull request title direct' do
    put :update, @wrong_update_params
    pull.issue.title.should_not =='update'
  end

  it 'should not update pull request body direct' do
    put :update, @wrong_update_params
    pull.issue.body.should_not =='updating'
  end
end

shared_examples_for 'user without pull request update rights' do
  it 'should not be able to perform update action' do
    put :update, @update_params
    response.should redirect_to(controller.current_user ? forbidden_path : new_user_session_path)
  end

  let(:pull) { @project.pull_requests.find(@pull) }
  it 'should not update pull request status' do
    put :update, @update_params
    pull.status.should_not =='closed'
  end
  it 'should not update pull request title' do
    put :update, @wrong_update_params
    pull.issue.title.should_not =='update'
  end

  it 'should not update pull request body' do
    put :update, @wrong_update_params
    pull.issue.body.should_not =='updating'
  end

  it 'should be able to perform merge action' do
    @pull.check
    put :merge, @update_params
    response.should_not be_success
  end

end

shared_examples_for 'pull request when project with issues turned off' do
  before { @project.update_attributes(has_issues: false) }
  it 'should be able to perform index action' do
    get :index, name_with_owner: @project.name_with_owner
    response.should render_template(:index)
  end

  it 'should be able to perform show action when pull request has been created' do
    @pull.check
    get :show, name_with_owner: @project.name_with_owner, id: @pull.serial_id
    response.should render_template(:show)
  end
end

describe Projects::PullRequestsController do
  include_context "pull request controller"

  context 'for global admin user' do
    before do
      @user.role = "admin"
      @user.save
    end

    it_should_behave_like 'pull request user with project guest rights'
    it_should_behave_like 'pull request user with project reader rights'
    it_should_behave_like 'user with pull request update rights'
    it_should_behave_like 'pull request when project with issues turned off'
  end

  context 'for project admin user' do
    before do
      create_relation(@project, @user, 'admin')
    end

    it_should_behave_like 'pull request user with project guest rights'
    it_should_behave_like 'pull request user with project reader rights'
    it_should_behave_like 'user with pull request update rights'
    it_should_behave_like 'pull request when project with issues turned off'
  end

  context 'for project owner user' do
    before do
      @user = @project.owner
      set_session_for(@user)
    end

    it_should_behave_like 'pull request user with project guest rights'
    it_should_behave_like 'pull request user with project reader rights'
    it_should_behave_like 'user with pull request update rights'
    it_should_behave_like 'pull request when project with issues turned off'
  end

  context 'for project reader user' do
    before do
      create_relation(@project, @user, 'reader')
    end

    it_should_behave_like 'pull request user with project guest rights'
    it_should_behave_like 'pull request user with project reader rights'
    it_should_behave_like 'user without pull request update rights'
    it_should_behave_like 'pull request when project with issues turned off'

    it 'should return 404' do
      get :show, name_with_owner: @project.name_with_owner, id: 999999
      render_template(file: "#{Rails.root}/public/404.html")
    end

    it 'should redirect to issue page' do
      get :show, name_with_owner: @project.name_with_owner, id: @issue.serial_id
      response.should redirect_to(project_issue_path(@project, @issue))
    end
  end

  context 'for project writer user' do
    before do
      create_relation(@project, @user, 'writer')
    end

    it_should_behave_like 'pull request user with project guest rights'
    it_should_behave_like 'pull request user with project reader rights'
    it_should_behave_like 'user without pull request update rights'
    it_should_behave_like 'pull request when project with issues turned off'
  end

=begin
  context 'for pull request assign user' do
    before do
      set_session_for(@pull request_user)
    end

    it_should_behave_like 'user without pull request update rights'
    it_should_behave_like 'pull request when project with issues turned off'
  end
=end

  context 'for guest' do
    let(:guest) { User.new }
    before do
      set_session_for(guest)
    end

    if APP_CONFIG['anonymous_access']

      it_should_behave_like 'pull request user with project guest rights'
      it_should_behave_like 'pull request when project with issues turned off'

    else
      it 'should not be able to perform index action' do
        get :index, name_with_owner: @project.name_with_owner
        response.should redirect_to(new_user_session_path)
      end

      it 'should not be able to perform show action' do
        @pull.check
        get :show, name_with_owner: @project.name_with_owner, id: @pull.serial_id
        response.should redirect_to(new_user_session_path)
      end

      it 'should not be able to perform index action on hidden project' do
        @project.update_attributes(visibility: 'hidden')
        get :index, name_with_owner: @project.name_with_owner
        response.should redirect_to(new_user_session_path)
      end
    end

    it 'should not be able to perform create action' do
      post :create, @create_params
      response.should redirect_to(new_user_session_path)
    end

    it 'should not create pull request object into db' do
      lambda{ post :create, @create_params }.should_not change{ PullRequest.count }
    end

    it_should_behave_like 'user without pull request update rights'
  end

  context 'send email messages' do
    before(:each) do
      @project_reader = FactoryGirl.create :user
      create_relation(@project, @project_reader, 'reader')
      @project_admin = FactoryGirl.create :user
      create_relation(@project, @project_admin, 'admin')
      @project_writer = FactoryGirl.create :user
      create_relation(@project, @project_writer, 'writer')

      set_session_for(@project_writer)
      ActionMailer::Base.deliveries = []
    end

    it 'should send two email messages to project admins' do
      post :create, @create_params
      ActionMailer::Base.deliveries.count.should == 2
    end

    it 'should send two email messages to admins and one to assignee' do
      post :create, @create_params.deep_merge(issue: {assignee_id: @project_reader.id})
      ActionMailer::Base.deliveries.count.should == 3
    end

    it 'should not duplicate email message' do
      post :create, @create_params.deep_merge(issue: {assignee_id: @project_admin.id})
      ActionMailer::Base.deliveries.count.should == 2 # send only to admins
      ActionMailer::Base.deliveries.first.to != ActionMailer::Base.deliveries.last.to
    end
  end
end
