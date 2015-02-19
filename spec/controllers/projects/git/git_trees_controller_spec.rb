require 'spec_helper'

describe Projects::Git::TreesController, type: :controller do

  before(:each) do
    stub_symlink_methods

    @project = FactoryGirl.create(:project)
    @params = { name_with_owner: @project.name_with_owner, treeish: "#{@project.name}-master" }
    fill_project @project
  end

  context 'for guest' do
    [:tags, :branches].each do |action|
      it "should be able to perform #{action} action with anonymous acccess", anonymous_access: true do
        get action, @params.merge(treeish: 'master')
        response.should be_success
      end

      it "should not be able to perform #{action} action without anonymous acccess", anonymous_access: false do
        get action, @params.merge(treeish: 'master')
        response.should_not be_success
      end
    end

    it "should be able to perform archive action with anonymous acccess", anonymous_access: true do
      get :archive, @params.merge(format: 'tar.gz')
      response.should be_success
    end

    it "should not be able to perform archive action without anonymous acccess", anonymous_access: false do
      get :archive, @params.merge(format: 'tar.gz')
      response.code.should == '401'
    end

    it 'should not be able to perform destroy action' do
      delete :destroy, @params.merge(treeish: 'master')
      response.should_not be_success
    end

    it 'should not be able to perform restore_branch action' do
      put :restore_branch, @params.merge(treeish: 'master')
      response.should_not be_success
    end

    it 'should not be able to perform create action' do
      post :create, @params.merge(treeish: '', from_ref: 'master', new_ref: 'master-1')
      response.should_not be_success
    end

  end

  context 'for other user' do
    before { set_session_for FactoryGirl.create(:user) }
    it 'should not be able to archive empty project' do
      %x(rm -rf #{@project.path})
      expect { get :archive, @params.merge(format: 'tar.gz') }.to raise_error(ActionController::RoutingError)
    end

    it 'should not be able to injection code with format' do
      expect { get :archive, @params.merge(format: "tar.gz master > /dev/null; echo 'I am hacker!';\#") }.to raise_error(ActionController::RoutingError)
    end

    it 'should not be able to injection code with treeish' do
      expect { get :archive, @params.merge(treeish: "master > /dev/null; echo 'I am hacker!';\#") }.to raise_error(ActionController::RoutingError)
    end

    it 'should be able to perform archive action' do
      get :archive, @params.merge(format: 'tar.gz')
      response.should be_success
    end

    it 'should not be able to perform destroy action' do
      delete :destroy, @params.merge(treeish: 'master')
      response.should_not be_success
    end

    it 'should not be able to perform restore_branch action' do
      put :restore_branch, @params.merge(treeish: 'master')
      response.should_not be_success
    end

    it 'should not be able to perform create action' do
      post :create, @params.merge(treeish: '', from_ref: 'master', new_ref: 'master-1')
      response.should_not be_success
    end

    [:tags, :branches].each do |action|
      it "should be able to perform #{action} action" do
        get action, @params.merge(treeish: 'master')
        response.should be_success
      end
    end
  end

  context 'for writer user' do
    before(:each) do
      user = FactoryGirl.create(:user)
      create_relation(@project, user, 'writer')
      set_session_for user
    end

    it 'should be able to perform destroy action' do
      delete :destroy, @params.merge(treeish: 'conflicts')
      response.should be_success
    end

    it 'should not be able to perform destroy action for master branch' do
      delete :destroy, @params.merge(treeish: 'master')
      response.should_not be_success
    end

    it 'should be able to perform restore_branch action' do
      put :restore_branch, @params.merge(treeish: 'master-1', sha: 'master')
      response.should be_success
    end

    it 'should be able to perform create action' do
      post :create, @params.merge(treeish: '', from_ref: 'master', new_ref: 'master-1')
      response.should be_success
    end
  end

  after(:all) {clean_projects_dir}
end
