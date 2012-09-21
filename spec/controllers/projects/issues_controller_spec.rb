# -*- encoding : utf-8 -*-
require 'spec_helper'

shared_context "issues controller" do
  before(:each) do
    stub_symlink_methods

    @project = FactoryGirl.create(:project)
    @issue_user = FactoryGirl.create(:user)

    @issue = FactoryGirl.create(:issue, :project_id => @project.id, :assignee_id => @issue_user.id)

    @project_with_turned_off_issues = FactoryGirl.create(:project, :has_issues => false)
    @turned_of_issue = FactoryGirl.create(:issue, :project_id => @project_with_turned_off_issues.id, :assignee_id => @issue_user.id)
  
    @user = FactoryGirl.create(:user)
    set_session_for(@user)

    @create_params = {
      :owner_name => @project.owner.uname, :project_name => @project.name,
      :issue => {
        :title => "issue1",
        :body => "issue body"
      },
      :assignee_id => @issue_user.id,
      :assignee_uname => @issue_user.uname
    }

    @update_params = {
      :owner_name => @project.owner.uname, :project_name => @project.name,
      :issue => {
        :title => "issue2"
      }
    }

  end

end

shared_examples_for 'issue user with project guest rights' do
  it 'should be able to perform index action' do
    get :index, :owner_name => @project.owner.uname, :project_name => @project.name
    response.should render_template(:index)
  end

  it 'should be able to perform show action' do
    get :show, :owner_name => @project.owner.uname, :project_name => @project.name, :id => @issue.serial_id
    response.should render_template(:show)
  end
end

shared_examples_for 'issue user with project reader rights' do

  it 'should be able to perform index action on hidden project' do
    @project.update_attributes(:visibility => 'hidden')
    get :index, :owner_name => @project.owner.uname, :project_name => @project.name
    response.should render_template(:index)
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
    response.code.should eq('200')
  end

  it 'should update issue title' do
    put :update, {:id => @issue.serial_id}.merge(@update_params)
    @issue.reload.title.should == 'issue2'
  end
end

shared_examples_for 'user without issue update rights' do
  it 'should not be able to perform update action' do
    put :update, {:id => @issue.serial_id}.merge(@update_params)
    response.should redirect_to(controller.current_user ? forbidden_path : new_user_session_path)
  end

  it 'should not update issue title' do
    put :update, {:id => @issue.serial_id}.merge(@update_params)
    @issue.reload.title.should_not == 'issue2'
  end
end

shared_examples_for 'user without issue destroy rights' do
  it 'should not be able to perform destroy action' do
    delete :destroy, :id => @issue.serial_id, :owner_name => @project.owner.uname, :project_name => @project.name
    response.should redirect_to(controller.current_user ? forbidden_path : new_user_session_path)
  end

  it 'should not reduce issues count' do
    lambda{ delete :destroy, :id => @issue.serial_id, :owner_name => @project.owner.uname, :project_name => @project.name }.should_not change{ Issue.count }
  end
end

shared_examples_for 'project with issues turned off' do
  it 'should not be able to perform index action' do
    get :index, :project_id => @project_with_turned_off_issues.id
    response.should redirect_to(forbidden_path)
  end

  it 'should not be able to perform show action' do
    get :show, :project_id => @project_with_turned_off_issues.id, :id => @turned_of_issue.serial_id
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
      @project.relations.create!(:actor_type => 'User', :actor_id => @user.id, :role => 'admin')
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
      @project.relations.create!(:actor_type => 'User', :actor_id => @user.id, :role => 'reader')
    end

    it_should_behave_like 'issue user with project guest rights'
    it_should_behave_like 'issue user with project reader rights'
    it_should_behave_like 'issue user with project writer rights'
    it_should_behave_like 'user without issue update rights'
    it_should_behave_like 'project with issues turned off'
    it_should_behave_like 'user without issue destroy rights'

    # it 'should not be able to perform create action on project' do
    #   post :create, @create_params
    #   response.should redirect_to(forbidden_path)
    # end

    # it 'should not create issue object into db' do
    #   lambda{ post :create, @create_params }.should change{ Issue.count }.by(0)
    # end
  end

  context 'for project writer user' do
    before(:each) do
      @project.relations.create!(:actor_type => 'User', :actor_id => @user.id, :role => 'writer')
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
        @project.update_attributes(:visibility => 'hidden')
        get :index, :owner_name => @project.owner.uname, :project_name => @project.name
        response.should redirect_to(forbidden_path)
      end

    else
      it 'should not be able to perform index action' do
        get :index, :owner_name => @project.owner.uname, :project_name => @project.name
        response.should redirect_to(new_user_session_path)
      end

      it 'should not be able to perform show action' do
        get :show, :owner_name => @project.owner.uname, :project_name => @project.name, :id => @issue.serial_id
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

    it 'should not create issue object into db' do
      lambda{ post :create, @create_params }.should_not change{ Issue.count }
    end

    it_should_behave_like 'user without issue update rights'
    it_should_behave_like 'user without issue destroy rights'
  end
end
