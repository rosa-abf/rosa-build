# -*- encoding : utf-8 -*-
require 'spec_helper'

describe Projects::PullRequestsController do

  before(:each) do
    stub_symlink_methods

    @project = FactoryGirl.create(:project)
    %x(cp -Rf #{Rails.root}/spec/tests.git/* #{@project.path})

    @pull = @project.pull_requests.new :issue_attributes => {:title => 'test', :body => 'testing'}
    @pull.issue.user, @pull.issue.project = @project.owner, @pull.base_project
    @pull.base_ref = 'master'
    @pull.head_project, @pull.head_ref = @project, 'non_conflicts'
    @pull.save

    @another_user = FactoryGirl.create(:user)
    @create_params = {:pull_request => {:issue_attributes => {:title => 'create', :body => 'creating'}, :base_ref => 'non_conflicts', :head_ref => 'master'},
                                     :owner_name => @project.owner.uname, :project_name => @project.name}
    @update_params = @create_params.merge(:pull_request => {:issue => {:title => 'update', :body => 'updating'}}, :id => @pull.id)
  end

  context 'for guest' do
    it 'should not be able to perform create action' do
      post :create, @create_params
      response.should redirect_to(new_user_session_path)
    end

    it 'should not be able to perform update action' do
      post :update, @update_params
      response.should redirect_to(new_user_session_path)
    end

    it 'should not be able to perform update title and body' do
      post :update, @update_params
      PullRequest.joins(:issue).where(:id => @pull.id, :issues => {:title => 'update', :body => 'updating'}).count.should == 0
    end
  end

  context 'for owner user' do
    before(:each) do
      set_session_for(@project.owner)
    end

    it 'should be able to perform create action' do
      post :create, @create_params
      PullRequest.joins(:issue).where(:issues => {:title => 'create', :body => 'creating'}).count.should == 1
    end

    it 'should be able to perform update action' do
      post :update, @update_params
      response.should redirect_to(project_pull_request_path(@project, @project.pull_requests.last))
    end

    it 'should be able to perform update title and body' do
      post :update, @update_params
      PullRequest.joins(:issue).where(:id => @pull.id, :issues => {:title => 'update', :body => 'updating'}).count.should == 1
    end
  end
end
