require 'spec_helper'

describe ProjectsController do
	before(:each) do
    @project = Factory(:project)
    @another_user = Factory(:user)
    @create_params = {:project => {:name => 'pro', :unixname => 'pro2'}}
    @update_params = {:project => {:name => 'pro2', :unixname => 'pro2'}}
	end

	context 'for guest' do
    it 'should not be able to perform index action' do
      get :index, :id => @project.id
      response.should redirect_to(forbidden_path)
    end

    it 'should not be able to perform update action' do
      get :update, {:id => @project.id}.merge(@update_params)
      response.should redirect_to(forbidden_path)
    end
  end

  context 'for admin' do
  	before(:each) do
  		@admin = Factory(:admin)
  		set_session_for(@admin)
		end

    it 'should be able to perform index action' do
      get :index, :id => @project.id
      response.should render_template(:index)
    end

    it 'should be able to perform update action' do
      put :update, {:id => @project.id}.merge(@update_params)
      response.should redirect_to(project_path(@project))
    end

    it 'should set flash notice on update success' do
      put :update, {:id => @project.id}.merge(@update_params)
      flash[:notice].should_not be_blank
    end

    it 'should be able to perform create action' do
      post :create, @create_params
      response.should redirect_to(project_path( Project.last.id ))
    end

    it 'should set flash notice on create success' do
      post :create, @create_params
      flash[:notice].should_not be_blank
    end
  end

  context 'for owner user' do
  	before(:each) do
  		@user = Factory(:user)
  		set_session_for(@user)
  		@project.update_attribute(:owner, @user)
  		r = @project.relations.build(:object_type => 'User', :object_id => @user.id, :role => 'admin')
  		r.save!
		end

    it 'should be able to perform update action' do
      put :update, {:id => @project.id}.merge(@update_params)
      response.should redirect_to(project_path(@project))
    end

    it 'should set flash notice on update success' do
      put :update, {:id => @project.id}.merge(@update_params)
      flash[:notice].should_not be_blank
    end
  end

  context 'for reader user' do
  	before(:each) do
  		@user = Factory(:user)
  		set_session_for(@user)
  		#@project.update_attribute(:owner, @user)
  		r = @project.relations.build(:object_type => 'User', :object_id => @user.id, :role => 'reader')
  		r.save!
		end

    it 'should not be able to perform index action' do
      get :index
      response.should render_template(:index)
    end

    it 'should not be able to perform show action' do
      get :show, :id => @project.id
      response.should render_template(:show)
    end

    #it 'should not be able to perform update action' do
    #  get :update, {:id => @project.id}.merge(@update_params)
    #  response.should redirect_to(forbidden_path)
    #end
#
    #it 'should set flash notice on update success' do
    #  put :update, {:id => @project.id}.merge(@update_params)
    #  flash[:notice].should_not be_blank
    #end
  end

  context 'for writer user' do
  	before(:each) do
  		@user = Factory(:user)
  		set_session_for(@user)
  		#@project.update_attribute(:owner, @user)
  		r = @project.relations.build(:object_type => 'User', :object_id => @user.id, :role => 'writer')
  		r.save!
		end

    it 'should not be able to perform update action' do
      put :update, {:id => @project.id}.merge(@update_params)
      response.should redirect_to(project_path(@project))
    end

    it 'should set flash notice on update success' do
      put :update, {:id => @project.id}.merge(@update_params)
      flash[:notice].should_not be_blank
    end
  end
end
