require 'spec_helper'

shared_examples_for 'user with create subscribe rights' do
  it 'should be able to perform create action' do
    post :create, @create_params
    response.should redirect_to(project_issue_path(@project, @issue))
  end

  it 'should create subscribe object into db' do
    lambda{ post :create, @create_params }.should change{ Subscribe.count }.by(1)
  end
end

shared_examples_for 'user without destroy subscribe rights' do
  it 'should not be able to perform destroy action' do
    delete :destroy, :id => @subscribe.id, :issue_id => @issue.id, :project_id => @project.id
    response.should redirect_to(forbidden_path)
  end

  it 'should not reduce subscribes count' do
    lambda{ delete :destroy, :id => @subscribe.id, :issue_id => @issue.id, :project_id => @project.id }.should change{ Subscribe.count }.by(0)
  end
end

describe SubscribesController do
  before(:each) do
    stub_rsync_methods

    @project = Factory(:project)
    @issue = Factory(:issue, :project_id => @project.id)
    @subscribe = Factory(:subscribe, :subscribeable => @issue, :user => @user)

    any_instance_of(Project, :versions => ['v1.0', 'v2.0'])

    @request.env['HTTP_REFERER'] = project_issue_path(@project, @issue)
  end

  context 'for global admin user' do
    before(:each) do
      @user = Factory(:admin)
      set_session_for(@user)
      @project.relations.create!(:object_type => 'User', :object_id => @user.id, :role => 'admin')
    end

    it 'should be able to perform create action' do
      post :create, :project_id => @project.id, :issue_id => @issue.id
      response.should redirect_to(project_issue_path(@project, @issue))
    end

    it 'should create issue object into db' do
      lambda{ post :create, :project_id => @project.id, :issue_id => @issue.id }.should change{ Subscribe.count }.by(1)
    end

    it 'should be able to perform destroy action' do
      delete :destroy, :id => @subscribe.id, :issue_id => @issue.id, :project_id => @project.id
      response.should redirect_to(forbidden_path)
    end

    it 'should reduce subscribes count' do
      lambda{ delete :destroy, :id => @subscribe.id, :issue_id => @issue.id, :project_id => @project.id }.should change{ Issue.count }.by(-1)
    end

    #it_should_behave_like 'user with create subscribe rights'
    #it_should_behave_like 'user with update stranger subscribe rights'
    #it_should_behave_like 'user with update own subscribe rights'
    #it_should_behave_like 'user without destroy subscribe rights'
  end

end
