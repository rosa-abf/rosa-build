# -*- encoding : utf-8 -*-
require 'spec_helper'

def create_pull to_ref, from_ref, owner, project = @project
  pull = project.pull_requests.new :issue_attributes => {:title => 'test', :body => 'testing'}
  pull.issue.user, pull.issue.project = owner, pull.to_project
  pull.to_ref, pull.from_ref, pull.from_project = to_ref, from_ref, project
  pull.save
  pull
end

describe Api::V1::PullRequestsController do
  before(:each) do
    stub_symlink_methods
    stub_redis
    @project = FactoryGirl.create(:project_with_commit)
    @pull = create_pull 'master', 'non_conflicts', @project.owner
    @create_params = {:pull_request => {:title => 'title', :body => 'body',
                                        :from_ref => 'conflicts', :to_ref => 'master'},
                      :project_id => @project.id, :format => :json}
  end

  context 'read and accessible abilities' do
    context 'for user' do
      before(:each) do
        http_login(@project.owner)
      end

      it 'can show pull request in own project' do
        get :show, :project_id => @project.id, :id => @pull.serial_id, :format => :json
        response.should be_success
      end

      it 'should render right template for show action' do
        get :show, :project_id => @project.id, :id => @pull.serial_id, :format => :json
        response.should render_template('api/v1/pull_requests/show')
      end

      it 'can show pull request in open project' do
        another_project = FactoryGirl.create(:project_with_commit)
        pull = create_pull 'master', 'non_conflicts', another_project.owner, another_project
        get :show, :project_id => another_project.id, :id => pull.serial_id, :format => :json
        response.should be_success
      end

      it 'can show pull request in own hidden project' do
        @project.update_column :visibility, 'hidden'
        get :show, :project_id => @project.id, :id => @pull.serial_id, :format => :json
        response.should be_success
      end

      it 'cant show pull request in hidden project' do
        another_project = FactoryGirl.create(:project_with_commit)
        pull = create_pull 'master', 'non_conflicts', another_project.owner, another_project
        another_project.update_column :visibility, 'hidden'

        get :show, :project_id => another_project.id, :id => pull.serial_id, :format => :json
        response.status.should == 403
      end

      it 'should return three pull requests' do
        own_hidden_project = FactoryGirl.create(:project_with_commit, :owner => @project.owner)
        own_hidden_project.update_column :visibility, 'hidden'
        own_hidden_pull = create_pull 'master', 'non_conflicts', own_hidden_project.owner, own_hidden_project
        membered_project = FactoryGirl.create(:project_with_commit)
        membered_pull = create_pull 'master', 'non_conflicts', membered_project.owner, membered_project
        membered_project.relations.create(:role => 'reader', :actor => @pull.user)

        get :all_index, :filter => 'all', :format => :json
        assigns[:pulls].should include(@pull)
        assigns[:pulls].should include(own_hidden_pull)
        assigns[:pulls].should include(membered_pull)
      end

      it 'should render right template for all index action' do
        get :all_index, :format => :json
        response.should render_template('api/v1/pull_requests/index')
      end

      it 'should return only assigned pull request' do
        own_hidden_project = FactoryGirl.create(:project_with_commit, :owner => @project.owner)
        own_hidden_project.update_column :visibility, 'hidden'
        own_hidden_pull = create_pull 'master', 'non_conflicts', own_hidden_project.owner, own_hidden_project
        own_hidden_pull.issue.update_column :assignee_id, @pull.user

        get :user_index, :format => :json
        assigns[:pulls].should include(own_hidden_pull)
        assigns[:pulls].count.should == 1
      end

      it 'should render right template for user index action' do
        get :user_index, :format => :json
        response.should render_template('api/v1/pull_requests/index')
      end
    end

    context 'for anonymous user' do
      it 'can show pull request in open project', :anonymous_access => true do
        get :show, :project_id => @project.id, :id => @pull.serial_id, :format => :json
        response.should be_success
      end

      it 'cant show pull request in hidden project', :anonymous_access => true do
        @project.update_column :visibility, 'hidden'
        get :show, :project_id => @project.id, :id => @pull.serial_id, :format => :json
        response.status.should == 403
      end

      it 'should not return any pull requests' do
        get :all_index, :filter => 'all', :format => :json
        response.status.should == 401
      end
    end
  end

  context 'create accessibility' do
    context 'for user' do
      before(:each) do
        http_login(@pull.user)
      end

      it 'can create pull request in own project' do
        lambda { post :create, @create_params }.should change{ PullRequest.count }.by(1)
      end

      it 'can create pull request in own hidden project' do
        own_hidden_project = FactoryGirl.create(:project_with_commit, :owner => @project.owner)
        own_hidden_project.update_column :visibility, 'hidden'
        lambda { post :create, @create_params.merge(:project_id => own_hidden_project.id) }.should
          change{ PullRequest.count }.by(1)
      end

      it 'can create pull request in open project' do
        lambda { post :create, @create_params.merge(:project_id => @another_project.id) }.should
          change{ PullRequest.count }.by(1)
      end

      it 'cant create pull request in hidden project' do
        hidden_project = FactoryGirl.create(:project_with_commit)
        hidden_project.update_column :visibility, 'hidden'

        lambda { post :create, @create_params.merge(:project_id => hidden_project.id) }.should
          change{ PullRequest.count }.by(0)

      end
    end

    context 'for anonymous user' do
      it 'cant create pull request in project', :anonymous_access => true do
        lambda { post :create, @create_params }.should change{ PullRequest.count }.by(0)
      end

      it 'cant create pull request in hidden project', :anonymous_access => true do
        hidden_project = FactoryGirl.create(:project_with_commit)
        hidden_project.update_column :visibility, 'hidden'
        lambda { post :create, @create_params.merge(:project_id => hidden_project.id) }.should
          change{ PullRequest.count }.by(0)
      end
    end
  end
end
