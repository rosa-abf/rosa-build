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
    fill_project @project          
  end

  context 'for guest' do
    [:tags, :branches].each do |action|
      it "should be able to perform #{action} action with anonymous acccess", :anonymous_access => true do
        get action, @params.merge(:treeish => 'master')
        response.should be_success
      end

      it "should not be able to perform #{action} action without anonymous acccess", :anonymous_access => false do
        get action, @params.merge(:treeish => 'master')
        response.should_not be_success
      end
    end

    it "should be able to perform archive action with anonymous acccess", :anonymous_access => true do
      stub(controller).render
      get :archive, @params.merge(:format => 'tar.gz')
      response.should be_success
    end

    it "should not be able to perform archive action without anonymous acccess", :anonymous_access => false do
      get :archive, @params.merge(:format => 'tar.gz')
      response.code.should == '401'
    end
  end

  context 'for other user' do
    it 'should not be able to archive empty project' do
      %x(rm -rf #{@project.path})
      set_session_for FactoryGirl.create(:user)
      expect { get :archive, @params.merge(:format => 'tar.gz') }.to raise_error(ActionController::RoutingError)
    end

    it 'should not be able to injection code with format' do
      set_session_for FactoryGirl.create(:user)
      expect { get :archive, @params.merge(:format => "tar.gz master > /dev/null; echo 'I am hacker!';\#") }.to raise_error(ActionController::RoutingError)
    end

    it 'should not be able to injection code with treeish' do
      set_session_for FactoryGirl.create(:user)
      expect { get :archive, @params.merge(:treeish => "master > /dev/null; echo 'I am hacker!';\#") }.to raise_error(ActionController::RoutingError)
    end

    it 'should be able to perform archive action' do
      stub(controller).render
      set_session_for FactoryGirl.create(:user)
      get :archive, @params.merge(:format => 'tar.gz')
      response.should be_success
    end

    [:tags, :branches].each do |action|
      it "should be able to perform #{action} action" do
        set_session_for FactoryGirl.create(:user)
        get action, @params.merge(:treeish => 'master')
        response.should be_success
      end
    end
  end

  after(:all) {clean_projects_dir}
end
