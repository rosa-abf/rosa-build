# -*- encoding : utf-8 -*-
require 'spec_helper'

describe Api::V1::IssuesController do
  before(:all) do
    stub_symlink_methods
    stub_redis
    any_instance_of(Project, :versions => ['v1.0', 'v2.0'])

    @issue = FactoryGirl.create(:issue)
    @project = @issue.project

    @membered_issue = FactoryGirl.create(:issue)
    @membered_project = @membered_issue.project
    @membered_project.relations.create(:role => 'reader', :actor => @issue.user)

    @open_issue = FactoryGirl.create(:issue)
    @open_project = @open_issue.project

    @own_hidden_project = FactoryGirl.create(:project, :owner => @issue.user)
    @own_hidden_project.update_column :visibility, 'hidden'
    @own_hidden_issue = FactoryGirl.create(:issue, :project => @own_hidden_project)

    @hidden_issue = FactoryGirl.create(:issue)
    @hidden_project = @hidden_issue.project
    @hidden_project.update_column :visibility, 'hidden'

    @create_params = {:issue => {:title => 'title', :body => 'body'}, :project_id => @project.id, :format => :json}
    @update_params = {:issue => {:title => 'new title'}, :project_id => @project.id, :id => @issue.serial_id, :format => :json}
  end

  context 'read and accessible abilities' do
    context 'for user' do
      before(:each) do
        http_login(@issue.user)
      end

      it 'can show issue in own project' do
        get :show, :project_id => @project.id, :id => @issue.serial_id, :format => :json
        response.should be_success
      end

      it 'can show issue in open project' do
        get :show, :project_id => @open_project.id, :id => @open_issue.serial_id, :format => :json
        response.should be_success
      end

      it 'can show issue in own hidden project' do
        get :show, :project_id => @own_hidden_project.id, :id => @own_hidden_issue.serial_id, :format => :json
        response.should be_success
      end

      it 'cant show issue in hidden project' do
        get :show, :project_id => @hidden_project.id, :id => @hidden_issue.serial_id, :format => :json
        response.status.should == 403
      end

      it 'should return three issues' do
        get :all_index, :filter => 'all', :format => :json
        assigns[:issues].should include(@issue)
        assigns[:issues].should include(@own_hidden_issue)
        assigns[:issues].should include(@membered_issue)
      end

      it 'should return only assigneed issue' do
        http_login(@issue.assignee)
        get :user_index, :format => :json
        assigns[:issues].should include(@issue)
        assigns[:issues].count.should == 1
      end
    end

    context 'for anonymous user' do
      it 'can show issue in open project', :anonymous_access => true do
        get :show, :project_id => @project.id, :id => @issue.serial_id, :format => :json
        response.should be_success
      end

      it 'cant show issue in hidden project', :anonymous_access => true do
        get :show, :project_id => @hidden_project.id, :id => @hidden_issue.serial_id, :format => :json
        response.status.should == 403
      end

      it 'should not return any issues' do
        get :all_index, :filter => 'all', :format => :json
        response.status.should == 401
      end
    end
  end

  context 'create accessibility' do
    context 'for user' do
      before(:each) do
        http_login(@issue.user)
        @count = Issue.count
      end

      it 'can create issue in own project' do
        post :create, @create_params
        Issue.count.should == @count+1
      end

      it 'can create issue in own hidden project' do
        post :create, @create_params.merge(:project_id => @own_hidden_project.id)
        Issue.count.should == @count+1
      end

      it 'can create issue in open project' do
        post :create, @create_params.merge(:project_id => @open_project.id)
        Issue.count.should == @count+1
      end

      it 'cant create issue in hidden project' do
        post :create, @create_params.merge(:project_id => @hidden_project.id)
        Issue.count.should == @count
      end
    end

    context 'for anonymous user' do
      before(:each) do
        @count = Issue.count
      end
      it 'cant create issue in project', :anonymous_access => true do
        post :create, @create_params
        Issue.count.should == @count
      end

      it 'cant create issue in hidden project', :anonymous_access => true do
        post :create, @create_params.merge(:project_id => @hidden_project.id)
        Issue.count.should == @count
      end
    end
  end

  context 'update accessibility' do
    context 'for user' do
      before(:each) do
        http_login(@issue.user)
      end

      it 'can update issue in own project' do
        put :update, @update_params
        @issue.reload.title.should == 'new title'
      end

      it 'can update issue in own hidden project' do
        put :update, @update_params.merge(:project_id => @own_hidden_project.id, :id => @own_hidden_issue.serial_id)
        @own_hidden_issue.reload.title.should == 'new title'
      end

      it 'cant update issue in open project' do
        put :update, @update_params.merge(:project_id => @open_project.id, :id => @open_issue.serial_id)
        @open_issue.reload.title.should_not == 'new title'
      end

      it 'cant update issue in hidden project' do
        put :update, @update_params.merge(:project_id => @hidden_project.id, :id => @hidden_issue.serial_id)
        @hidden_issue.reload.title.should_not == 'title'
      end
    end

    context 'for anonymous user' do
      before(:each) do
        @count = Issue.count
      end
      it 'cant update issue in project', :anonymous_access => true do
        put :update, @update_params
        response.status.should == 401
      end

      it 'cant update issue in hidden project', :anonymous_access => true do
        put :update, @update_params.merge(:project_id => @hidden_project.id, :id => @hidden_issue.serial_id)
        response.status.should == 401
      end
    end
  end
  after(:all) do
    User.destroy_all
    Platform.destroy_all
  end
end
