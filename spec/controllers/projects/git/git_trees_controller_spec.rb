# -*- encoding : utf-8 -*-
require 'spec_helper'

describe Projects::Git::TreesController do

  before(:each) do
    stub_symlink_methods

    @project = FactoryGirl.create(:project)
    @another_user = FactoryGirl.create(:user)
    @params = { :owner_name => @project.owner.uname,
                :project_name => @project.name,
                :treeish => "#{@project.owner.uname}-#{@project.name}-master"}
  end

  context 'for guest' do
    it 'should be able to perform archive action with anonymous acccess', :anonymous_access => true do
      stub(controller).render
      fill_project @project
      get :archive, @params.merge(:format => 'tar.gz')
      response.should be_success
    end

    it 'should not be able to perform archive action without anonymous acccess', :anonymous_access => false do
      fill_project @project
      get :archive, @params.merge(:format => 'tar.gz')
      response.code.should == '401'
    end
  end

  context 'for other user' do
    it 'should not be able to archive empty project' do
      @user = FactoryGirl.create(:user)
      set_session_for(@user)
      expect { get :archive, @params.merge(:format => 'tar.gz') }.to raise_error(ActionController::RoutingError)
    end

    it 'should not be able to injection code with format' do
      fill_project @project
      @user = FactoryGirl.create(:user)
      set_session_for(@user)
      expect { get :archive, @params.merge(:format => "tar.gz master > /dev/null; echo 'I am hacker!';\#") }.to raise_error(ActionController::RoutingError)
    end

    it 'should not be able to injection code with treeish' do
      fill_project @project
      @user = FactoryGirl.create(:user)
      set_session_for(@user)
      expect { get :archive, @params.merge(:treeish => "master > /dev/null; echo 'I am hacker!';\#") }.to raise_error(ActionController::RoutingError)
    end

    it 'should be able to perform archive action' do
      stub(controller).render
      fill_project @project
      @user = FactoryGirl.create(:user)
      set_session_for(@user)
      get :archive, @params.merge(:format => 'tar.gz')
      response.should be_success
    end
  end

  after(:all) {clean_projects_dir}
end
