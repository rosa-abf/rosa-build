require 'spec_helper'

shared_examples_for 'personal repository viewer' do
  it 'should be able to show personal repository' do
    get :show, :id => @repository.id
    response.should render_template(:show)
  end
end

shared_examples_for 'personal repository owner' do
  it_should_behave_like 'personal repository viewer'

  it 'should be able to perform add_project action' do
    get :add_project, :id => @repository.id
    response.should render_template(:projects_list)
  end

  it 'should be able to add project personal repository with project_id param' do
    get :add_project, :id => @repository.id, :project_id => @project.id
    response.should redirect_to(personal_repository_path(@repository))
  end

  it 'should be able to perform remove_project action' do
    get :remove_project, :id => @repository.id, :project_id => @project.id
    response.should redirect_to(personal_repository_path(@repository))
  end


  it 'should be able to perform change_visibility action' do
    get :change_visibility, :id => @repository.id
    response.should redirect_to(settings_personal_repository_path(@repository))
  end

  it 'should be able to change visibility of repository' do
    get :change_visibility, :id => @repository.id
    @repository.platform.reload.visibility.should == 'open'
  end

  it 'should be able to perform settings action' do 
    get :settings, :id => @repository.id 
    response.should render_template(:settings)
  end
end


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

      @project.update_attribute(:owner, @admin)
		end

    it_should_behave_like 'personal repository owner'
    it_should_behave_like 'repository user with add project rights'
    it_should_behave_like 'repository user with remove project rights'
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

      @project.update_attribute(:owner, @user)

  		@repository.update_attribute(:owner, @user)
  		@repository.relations.create!(:object_type => 'User', :object_id => @user.id, :role => 'admin')

  		@repository.platform.update_attribute(:owner, @user)
  		@repository.platform.relations.create!(:object_type => 'User', :object_id => @user.id, :role => 'admin')
		end

    it_should_behave_like 'personal repository owner'
    it_should_behave_like 'repository user with add project rights'
    it_should_behave_like 'repository user with remove project rights'
  end

  context 'for reader user' do
  	before(:each) do
  		@user = Factory(:user)
  		set_session_for(@user)
  		@repository.relations.create!(:object_type => 'User', :object_id => @user.id, :role => 'reader')
		end

    it_should_behave_like 'personal repository viewer'

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
