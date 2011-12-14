require 'spec_helper'
#require 'shared_examples/collaborators_controller'

describe CollaboratorsController do
	before(:each) do
    @project = Factory(:project)
    @another_user = Factory(:user)
    @update_params = {:user => {:read => {@another_user.id => '1'}}}
	end

	context 'for guest' do
    it 'should not be able to perform index action' do
      get :index, :project_id => @project.id
      response.should redirect_to(new_user_session_path)
    end

    it 'should not be able to perform update action' do
      post :update, {:project_id => @project.id}.merge(@update_params)
      response.should redirect_to(new_user_session_path)
    end
  end

  context 'for global admin' do
  	before(:each) do
  		@admin = Factory(:admin)
  		set_session_for(@admin)
		end

    it_should_behave_like 'show collaborators list'
    it_should_behave_like 'update collaborators'
    it_should_behave_like 'update collaborator relation'
  end

  context 'for admin user' do
    before(:each) do
      @user = Factory(:user)
      @user.relations
      set_session_for(@user)
      @group = Factory(:group)
      @project.relations.create!(:object_type => 'User', :object_id => @user.id, :role => 'reader')
    end

    it_should_behave_like 'show collaborators list'
    it_should_behave_like 'update collaborators'
    it_should_behave_like 'update collaborator relation'

    it 'should add new collaborator with reader role' do
      @params = {:member_id => @another_user.id.to_s, :project_id => @project.id.to_s}
      post :add, @params
      @project.relations.exists?(:object_type => 'User', :object_id => @another_user.id, :role => 'reader').should be_true
    end

    it 'should add new group with reader role' do
      @params = {:group_id => @group.id.to_s, :project_id => @project.id.to_s}
      post :add, @params
      @project.relations.exists?(:object_type => 'Group', :object_id => @group.id, :role => 'reader').should be_true
    end

    it_should_behave_like 'be_able_to_perform_index#collaborators'
    it_should_behave_like 'be_able_to_perform_update#collaborators'
    it_should_behave_like 'update_collaborator_relation'
  end

  context 'for owner user' do
  	before(:each) do
  		@user = Factory(:user)
  		set_session_for(@user)
  		@project.update_attribute(:owner, @user)
  		@project.relations.create!(:object_type => 'User', :object_id => @user.id, :role => 'admin')
		end

    it_should_behave_like 'show collaborators list'
    it_should_behave_like 'update collaborators'
    it_should_behave_like 'update collaborator relation'
  end

  context 'for reader user' do
  	before(:each) do
  		@user = Factory(:user)
  		set_session_for(@user)
  		@project.update_attribute(:owner, @user)
  		@project.relations.create!(:object_type => 'User', :object_id => @user.id, :role => 'reader')
		end

    it_should_behave_like 'not show collaborators list'
    it_should_behave_like 'not update collaborators'
    it_should_behave_like 'not update collaborator relation'
  end

  context 'for writer user' do
  	before(:each) do
  		@user = Factory(:user)
  		set_session_for(@user)
  		@project.update_attribute(:owner, @user)
  		@project.relations.create!(:object_type => 'User', :object_id => @user.id, :role => 'writer')
		end

    it_should_behave_like 'not show collaborators list'
    it_should_behave_like 'not update collaborators'
    it_should_behave_like 'not update collaborator relation'
  end
end
