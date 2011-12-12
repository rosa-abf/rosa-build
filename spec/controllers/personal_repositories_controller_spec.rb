require 'spec_helper'
#require 'shared_examples/personal_repositories_controller'

describe PersonalRepositoriesController do
	before(:each) do
    stub_rsync_methods

    @repository = Factory(:personal_repository)
    @platform = Factory(:platform)
    @project = Factory(:project)
    @another_user = Factory(:user)
    @create_params = {:repository => {:name => 'pro', :description => 'pro2'}, :platform_id => @platform.id}
	end

	context 'for guest' do
    [:show, :add_project, :remove_project, :settings, :change_visibility].each do |action|
      it "should not be able to perform #{ action } action" do
        get action, :id => @repository.id
        response.should redirect_to(new_user_session_path)
      end
    end
  end

  context 'for admin' do
  	before(:each) do
  		@admin = Factory(:admin)
  		set_session_for(@admin)
		end

    it_should_behave_like 'show personal repository'
    it_should_behave_like 'add project to personal repository'
    it_should_behave_like 'add project personal repository with project_id param'
    it_should_behave_like 'add_project_to_repository'
    it_should_behave_like 'remove project from repository'
    it_should_behave_like 'remove project from personal repository'
    it_should_behave_like 'change visibility'
    it_should_behave_like 'settings personal repository'
  end

  context 'for anyone except admin' do
  	before(:each) do
  		@user = Factory(:user)
  		set_session_for(@user)
		end

  end

  context 'for owner user' do
  	before(:each) do
  		@user = Factory(:user)
  		set_session_for(@user)

  		@repository.update_attribute(:owner, @user)
  		@repository.relations.create!(:object_type => 'User', :object_id => @user.id, :role => 'admin')

  		@repository.platform.update_attribute(:owner, @user)
  		@repository.platform.relations.create!(:object_type => 'User', :object_id => @user.id, :role => 'admin')
		end

    it_should_behave_like 'show personal repository'
    it_should_behave_like 'change visibility'
    it_should_behave_like 'add project to personal repository'
    it_should_behave_like 'add project personal repository with project_id param'
    it_should_behave_like 'add_project_to_repository'
    it_should_behave_like 'remove project from personal repository'
    it_should_behave_like 'remove project from repository'
    it_should_behave_like 'settings personal repository'
  end

  context 'for reader user' do
  	before(:each) do
  		@user = Factory(:user)
  		set_session_for(@user)
  		@repository.relations.create!(:object_type => 'User', :object_id => @user.id, :role => 'reader')
		end

    it_should_behave_like 'show personal repository'

    it 'should not be able to perform add_project action' do
      get :add_project, :id => @repository.id
      response.should redirect_to(forbidden_path)
    end

    it 'should not be able to perform add_project action with project_id param' do
      get :add_project, :id => @repository.id, :project_id => @project.id
      response.should redirect_to(forbidden_path)
    end

    it 'should not be able to perform settings action' do
      get :settings, :id => @repository.id
      response.should redirect_to(forbidden_path)
    end

    it 'should not be able to perform change_visibility action' do
      get :change_visibility, :id => @repository.id
      response.should redirect_to(forbidden_path)
    end

    it 'should not change visibility of repository' do
      get :change_visibility, :id => @repository.id
      @repository.platform.reload.visibility.should == 'hidden'
    end
  end

end
