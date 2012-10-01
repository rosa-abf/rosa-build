# -*- encoding : utf-8 -*-
require 'spec_helper'

shared_context "pull request controller" do
  after { FileUtils.rm_rf File.join(Rails.root, "tmp", Rails.env, "pull_requests") }
  before do
    FileUtils.rm_rf(APP_CONFIG['root_path'])
    stub_symlink_methods

    @project = FactoryGirl.create(:project)
    %x(cp -Rf #{Rails.root}/spec/tests.git/* #{@project.path})

    @pull = @project.pull_requests.new :issue_attributes => {:title => 'test', :body => 'testing'}
    @pull.issue.user, @pull.issue.project = @project.owner, @pull.base_project
    @pull.base_ref = 'master'
    @pull.head_project, @pull.head_ref = @project, 'non_conflicts'
    @pull.save

    @create_params = {
      :pull_request => {:issue_attributes => {:title => 'create', :body => 'creating'},
                        :base_ref => 'non_conflicts',
                        :head_ref => 'master'},
      :base_project_id => @project.id,
      :owner_name => @project.owner.uname,
      :project_name => @project.name }
    @update_params = @create_params.merge(
      :pull_request => {:issue_attributes => {:title => 'update', :body => 'updating', :id => @pull.issue.id}},
      :id => @pull.serial_id)

    @user = FactoryGirl.create(:user)
    set_session_for(@user)
  end

end

shared_examples_for 'pull request user with project guest rights' do
  it 'should be able to perform index action' do
    get :index, :owner_name => @project.owner.uname, :project_name => @project.name
    response.should render_template(:index)
  end

  it 'should be able to perform show action when pull request has been created' do
    @pull.check
    get :show, :owner_name => @project.owner.uname, :project_name => @project.name, :id => @pull.serial_id
    response.should render_template(:show)
  end
end

shared_examples_for 'pull request user with project reader rights' do
  it 'should be able to perform index action on hidden project' do
    @project.update_attributes(:visibility => 'hidden')
    get :index, :owner_name => @project.owner.uname, :project_name => @project.name
    response.should render_template(:index)
  end

  it 'should be able to perform create action' do
    post :create, @create_params
    response.should redirect_to(project_pull_request_path(@project, @project.pull_requests.last))
  end

  it 'should create pull request object into db' do
    lambda{ post :create, @create_params }.should change{ PullRequest.joins(:issue).
      where(:issues => {:title => 'create', :body => 'creating'}).count }.by(1)
  end

  it "should not create same pull" do
    post :create, @create_params.merge({:pull_request => {:issue_attributes => {:title => 'same', :body => 'creating'}, :head_ref => 'non_conflicts', :base_ref => 'master'}, :base_project_id => @project.id})
    PullRequest.joins(:issue).where(:issues => {:title => 'same', :body => 'creating'}).count.should == 0
  end

  it "should not create already up-to-date pull" do
    post :create, @create_params.merge({:pull_request => {:issue_attributes => {:title => 'already', :body => 'creating'}, :base_ref => 'master', :head_ref => 'master'}, :base_project_id => @project.id})
    PullRequest.joins(:issue).where(:issues => {:title => 'already', :body => 'creating'}).count.should == 0
  end
end

shared_examples_for 'user with pull request update rights' do
  it 'should be able to perform update action' do
    put :update, @update_params
    response.code.should eq('200')
  end

  let(:issue) { @project.pull_requests.find(@pull).issue }
  it 'should update pull request title and body' do
    put :update, @update_params
    issue.title.should =='update'
  end

  it 'should update pull request body' do
    put :update, @update_params
    issue.body.should =='updating'
  end
end

shared_examples_for 'user without pull request update rights' do
  it 'should not be able to perform update action' do
    put :update, @update_params
    response.should redirect_to(controller.current_user ? forbidden_path : new_user_session_path)
  end

  let(:issue) { @project.pull_requests.find(@pull).issue }
  it 'should not update pull request title and body' do
    put :update, @update_params
    issue.title.should_not =='update'
  end

  it 'should not update pull request body' do
    put :update, @update_params
    issue.body.should_not =='updating'
  end
end

shared_examples_for 'project with issues turned off' do
  before { @project.update_attributes(:has_issues => false) }
  it 'should be able to perform index action' do
    get :index, :project_id => @project.id
    response.should render_template(:index)
  end

  it 'should be able to perform show action when pull request has been created' do
    @pull.check
    get :show, :owner_name => @project.owner.uname, :project_name => @project.name, :id => @pull.serial_id
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
    it_should_behave_like 'project with issues turned off'
  end

  context 'for project admin user' do
    before do
      @project.relations.create!(:actor_type => 'User', :actor_id => @user.id, :role => 'admin')
    end

    it_should_behave_like 'pull request user with project guest rights'
    it_should_behave_like 'pull request user with project reader rights'
    it_should_behave_like 'user with pull request update rights'
    it_should_behave_like 'project with issues turned off'
  end

  context 'for project owner user' do
    before do
      @user = @project.owner
      set_session_for(@user)
    end

    it_should_behave_like 'pull request user with project guest rights'
    it_should_behave_like 'pull request user with project reader rights'
    it_should_behave_like 'user with pull request update rights'
    it_should_behave_like 'project with issues turned off'
  end

  context 'for project reader user' do
    before do
      @project.relations.create!(:actor_type => 'User', :actor_id => @user.id, :role => 'reader')
    end

    it_should_behave_like 'pull request user with project guest rights'
    it_should_behave_like 'pull request user with project reader rights'
    it_should_behave_like 'user without pull request update rights'
    it_should_behave_like 'project with issues turned off'
  end

  context 'for project writer user' do
    before do
      @project.relations.create!(:actor_type => 'User', :actor_id => @user.id, :role => 'writer')
    end

    it_should_behave_like 'pull request user with project guest rights'
    it_should_behave_like 'pull request user with project reader rights'
    it_should_behave_like 'user without pull request update rights'
    it_should_behave_like 'project with issues turned off'
  end

=begin
  context 'for pull request assign user' do
    before do
      set_session_for(@pull request_user)
    end

    it_should_behave_like 'user without pull request update rights'
    it_should_behave_like 'project with issues turned off'
  end
=end

  context 'for guest' do
    let(:guest) { User.new }
    before do
      set_session_for(guest)
    end

    if APP_CONFIG['anonymous_access']
      
      it_should_behave_like 'pull request user with project guest rights'
      it_should_behave_like 'project with issues turned off'
      
    else
      it 'should not be able to perform index action' do
        get :index, :owner_name => @project.owner.uname, :project_name => @project.name
        response.should redirect_to(new_user_session_path)
      end

      it 'should not be able to perform show action' do
        @pull.check
        get :show, :owner_name => @project.owner.uname, :project_name => @project.name, :id => @pull.serial_id
        response.should redirect_to(new_user_session_path)
      end

      it 'should not be able to perform index action on hidden project' do
        @project.update_attributes(:visibility => 'hidden')
        get :index, :owner_name => @project.owner.uname, :project_name => @project.name
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
end
