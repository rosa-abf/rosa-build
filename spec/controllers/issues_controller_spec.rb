require 'spec_helper'

shared_examples_for 'issue user with project reader rights' do
  #it_should_behave_like 'user with rights to view issues'
  it 'should be able to perform index action' do
    get :index, :project_id => @project.id
    response.should render_template(:index)
  end

  it 'should be able to perform show action' do
    get :show, :project_id => @project.id, :id => @issue.serial_id
    response.should render_template(:show)
  end
end

shared_examples_for 'issue user with project writer rights' do
  it 'should be able to perform create action' do
    post :create, @create_params
    response.should redirect_to(project_issues_path(@project))
  end

  it 'should create issue object into db' do
    lambda{ post :create, @create_params }.should change{ Issue.count }.by(1)
  end
end

shared_examples_for 'user with issue update rights' do
  it 'should be able to perform update action' do
    put :update, {:id => @issue.serial_id}.merge(@update_params)
    response.should redirect_to([@project, @issue])
  end

  it 'should update issue title' do
    put :update, {:id => @issue.serial_id}.merge(@update_params)
    @issue.reload.title.should == 'issue2'
  end
end

shared_examples_for 'user without issue update rights' do
  it 'should not be able to perform update action' do
    put :update, {:id => @issue.serial_id}.merge(@update_params)
    response.should redirect_to(forbidden_path)
  end

  it 'should not update issue title' do
    put :update, {:id => @issue.serial_id}.merge(@update_params)
    @issue.reload.title.should_not == 'issue2'
  end
end

shared_examples_for 'user without issue destroy rights' do
  it 'should not be able to perform destroy action' do
    delete :destroy, :id => @issue.serial_id, :project_id => @project.id
    response.should redirect_to(forbidden_path)
  end

  it 'should not reduce issues count' do
    lambda{ delete :destroy, :id => @issue.serial_id, :project_id => @project.id }.should change{ Issue.count }.by(0)
  end
end

shared_examples_for 'project with issues turned off' do
  pending 'should not be able to perform index action' do
    get :index, :project_id => @project_with_turned_off_issues.id
    #response.should redirect_to(forbidden_path)
    response.should render_template(:index)
  end

  it 'should not be able to perform show action' do
    get :show, :project_id => @project_with_turned_off_issues.id, :id => @turned_of_issue.serial_id
    response.should redirect_to(forbidden_path)
  end
end

describe IssuesController do
  before(:each) do
    stub_rsync_methods

    @project = Factory(:project)
    @issue_user = Factory(:user)

    any_instance_of(Project, :versions => ['v1.0', 'v2.0'])

    @issue = Factory(:issue, :project_id => @project.id, :user_id => @issue_user.id)
    @create_params = {
      :project_id => @project.id,
      :issue => {
        :title => "issue1",
        :body => "issue body",
        :project_id => @project.id
      },
      :user_id => @issue_user.id,
      :user_uname => @issue_user.uname
    }
    @update_params = {
      :project_id => @project.id,
      :issue => {
        :title => "issue2"
      }
    }

    @project_with_turned_off_issues = Factory(:project, :has_issues => false)
    @turned_of_issue = Factory(:issue, :project_id => @project_with_turned_off_issues.id, :user_id => @issue_user.id)
  end

  context 'for global admin user' do
    before(:each) do
      @admin = Factory(:admin)
      set_session_for(@admin)
    end

    it_should_behave_like 'user without issue destroy rights'
  end

  context 'for project admin user' do
    before(:each) do
      #@admin = Factory(:admin)
      #set_session_for(@admin)
      @user = Factory(:user)
      set_session_for(@user)
      @project.relations.create!(:object_type => 'User', :object_id => @user.id, :role => 'admin')
    end

    it_should_behave_like 'issue user with project reader rights'
    it_should_behave_like 'issue user with project writer rights'
    it_should_behave_like 'user with issue update rights'
    it_should_behave_like 'user without issue destroy rights'
    it_should_behave_like 'project with issues turned off'
  end

  context 'for project owner user' do
    before(:each) do
      @user = Factory(:user)
      set_session_for(@user)
      @project.update_attribute(:owner, @user)
      @project.relations.create!(:object_type => 'User', :object_id => @user.id, :role => 'admin')
    end

    it_should_behave_like 'issue user with project reader rights'
    it_should_behave_like 'issue user with project writer rights'
    it_should_behave_like 'user with issue update rights'
    it_should_behave_like 'user without issue destroy rights'
    it_should_behave_like 'project with issues turned off'
  end

  context 'for project reader user' do
    before(:each) do
      @user = Factory(:user)
      set_session_for(@user)
      @project.relations.create!(:object_type => 'User', :object_id => @user.id, :role => 'reader')
    end

    it_should_behave_like 'issue user with project reader rights'
    it_should_behave_like 'user without issue update rights'
    it_should_behave_like 'user without issue destroy rights'
    it_should_behave_like 'project with issues turned off'

    it 'should not be able to perform create action' do
      post :create, @create_params
      response.should redirect_to(forbidden_path)
    end

    it 'should not create issue object into db' do
      lambda{ post :create, @create_params }.should change{ Issue.count }.by(0)
    end
  end

  context 'for project writer user' do
    before(:each) do
      @user = Factory(:user)
      set_session_for(@user)
      @project.relations.create!(:object_type => 'User', :object_id => @user.id, :role => 'writer')
    end

    it_should_behave_like 'issue user with project reader rights'
    it_should_behave_like 'issue user with project writer rights'
    it_should_behave_like 'user without issue update rights'
    it_should_behave_like 'user without issue destroy rights'
    it_should_behave_like 'project with issues turned off'
  end

  context 'for issue assign user' do
    before(:each) do
      set_session_for(@issue_user)
      #@project.relations.create!(:object_type => 'User', :object_id => @user.id, :role => 'writer')
    end

    it_should_behave_like 'user with issue update rights'
    it_should_behave_like 'user without issue destroy rights'
    it_should_behave_like 'project with issues turned off'
  end
end
