# -*- encoding : utf-8 -*-
require 'spec_helper'

shared_examples_for 'api repository user with reader rights' do
  it_should_behave_like 'api repository user with show rights'
end

shared_examples_for 'api repository user with reader rights for hidden platform' do
  before(:each) do
    @platform.update_column(:visibility, 'hidden')
  end

  it_should_behave_like 'api repository user with show rights'
end

shared_examples_for 'api repository user without reader rights for hidden platform' do
  before(:each) do
    @platform.update_column(:visibility, 'hidden')
  end

  it_should_behave_like 'api repository user without show rights'
end

shared_examples_for "api repository user with show rights" do
  it 'should be able to perform show action' do
    get :show, :id => @repository.id, :format => :json
    response.should render_template(:show)
  end
  it 'should be able to perform projects action' do
    get :projects, :id => @repository.id, :format => :json
    response.should render_template(:projects)
  end
end

shared_examples_for "api repository user without show rights" do
  it 'should not be able to perform show action' do
    get :show, :id => @repository.id, :format => :json
    response.body.should == {"message" => "Access violation to this page!"}.to_json
  end
end

shared_examples_for "api repository user without key_pair rights" do
  it 'should not be able to perform key_pair action' do
    get :key_pair, :id => @repository.id, :format => :json
    response.should_not be_success
  end
end

shared_examples_for 'api repository user with writer rights' do

  context 'api repository user with update rights' do
    before do
      put :update, {:repository => {:description => 'new description'}, :id => @repository.id}, :format => :json
    end

    it 'should be able to perform update action' do
      response.should be_success
    end
    it 'ensures that repository has been updated' do
      @repository.reload
      @repository.description.should == 'new description'
    end
  end

  context 'api repository user with start/stop sync rights' do
    [:start_sync, :stop_sync].each do |action|
      it "should be able to perform #{action} action" do
        put action, :id => @repository.id, :format => :json
        response.should be_success
      end
    end
  end

  context 'api repository user with add_member rights' do
    let(:member) { FactoryGirl.create(:user) }
    before do
      put :add_member, {:member_id => member.id, :type => 'User', :id => @repository.id}, :format => :json
    end

    it 'should be able to perform add_member action' do
      response.should be_success
    end
    it 'ensures that new member has been added to repository' do
      @repository.members.should include(member)
    end
  end

  context 'api repository user with remove_member rights' do
    let(:member) { FactoryGirl.create(:user) }
    before do
      @repository.add_member(member)
      delete :remove_member, {:member_id => member.id, :type => 'User', :id => @repository.id}, :format => :json
    end

    it 'should be able to perform remove_member action' do
      response.should be_success
    end
    it 'ensures that member has been removed from repository' do
      @repository.members.should_not include(member)
    end
  end

  context 'api repository user with destroy rights' do
    it 'should be able to perform destroy action for main platform' do
      delete :destroy, :id => @repository.id, :format => :json
      response.should be_success
    end
    it 'ensures that repository of main platform has been destroyed' do
      lambda { delete :destroy, :id => @repository.id, :format => :json }.should change{ Repository.count }.by(-1)
    end

    context 'repository with name "main" of personal platform' do
      # hook for "ActiveRecord::ActiveRecordError: name is marked as readonly"
      before { Repository.where(:id => @personal_repository.id).update_all("name = 'main'") }
      it 'should not be able to perform destroy action' do
        delete :destroy, :id => @personal_repository.id, :format => :json
        response.should_not be_success
      end
      it 'ensures that repository has not been destroyed' do
        lambda { delete :destroy, :id => @personal_repository.id, :format => :json }.should_not change{ Repository.count }
      end
    end
    it 'should be able to perform destroy action for repository with name not "main" of personal platform' do
      delete :destroy, :id => @personal_repository.id, :format => :json
      response.should be_success
    end
    it 'ensures that repository with name not "main" of personal platform has been destroyed' do
      lambda { delete :destroy, :id => @personal_repository.id, :format => :json }.should change{ Repository.count }.by(-1)
    end
  end

  context 'api repository user with update signatures rights' do
    before do
      kp = FactoryGirl.build(:key_pair)
      put :signatures, :id => @repository.id, :repository => {:public => kp.public, :secret => kp.secret}, :format => :json
    end
    it 'should be able to perform signatures action' do
      response.should be_success
    end
    it 'ensures that signatures has been updated' do
      @repository.key_pair.should_not be_nil
    end
  end

end

shared_examples_for 'api repository user with project manage rights' do

  context 'api repository user with add_project rights' do
    before { put :add_project, :id => @repository.id, :project_id => @project.id, :format => :json }
    it 'should be able to perform add_project action' do
      response.should be_success
    end
    it 'ensures that project has been added to repository' do
      @repository.projects.should include(@project)
    end
  end

  context 'api repository user with remove_project rights' do
    before do
      @repository.projects << @project
      delete :remove_project, :id => @repository.id, :project_id => @project.id, :format => :json
    end
    it 'should be able to perform remove_project action' do
      response.should be_success
    end
    it 'ensures that project has been removed from repository' do
      @repository.reload
      @repository.projects.should_not include(@project)
    end
  end

end

shared_examples_for 'api repository user without writer rights' do

  context 'api repository user without update rights' do
    before do
      put :update, {:repository => {:description => 'new description'}, :id => @repository.id}, :format => :json
    end

    it 'should not be able to perform update action' do
      response.should_not be_success
    end
    it 'ensures that repository has not been updated' do
      @repository.reload
      @repository.description.should_not == 'new description'
    end
  end

  context 'api repository user without start/stop sync rights' do
    [:start_sync, :stop_sync].each do |action|
      it "should not be able to perform #{action} action" do
        put action, :id => @repository.id, :format => :json
        response.should_not be_success
      end
    end
  end

  context 'api repository user without add_member rights' do
    let(:member) { FactoryGirl.create(:user) }
    before do
      put :add_member, {:member_id => member.id, :type => 'User', :id => @repository.id}, :format => :json
    end

    it 'should not be able to perform add_member action' do
      response.should_not be_success
    end
    it 'ensures that new member has not been added to repository' do
      @repository.members.should_not include(member)
    end
  end

  context 'api repository user without remove_member rights' do
    let(:member) { FactoryGirl.create(:user) }
    before do
      @repository.add_member(member)
      delete :remove_member, {:member_id => member.id, :type => 'User', :id => @repository.id}, :format => :json
    end

    it 'should be able to perform update action' do
      response.should_not be_success
    end
    it 'ensures that member has not been removed from repository' do
      @repository.members.should include(member)
    end
  end

  context 'api repository user without destroy rights' do
    it 'should not be able to perform destroy action for repository of main platform' do
      delete :destroy, :id => @repository.id, :format => :json
      response.should_not be_success
    end
    it 'ensures that repository of main platform has not been destroyed' do
      lambda { delete :destroy, :id => @repository.id, :format => :json }.should_not change{ Repository.count }
    end
    it 'should not be able to perform destroy action for repository of personal platform' do
      delete :destroy, :id => @personal_repository.id, :format => :json
      response.should_not be_success
    end
    it 'ensures that repository of personal platform has not been destroyed' do
      lambda { delete :destroy, :id => @personal_repository.id, :format => :json }.should_not change{ Repository.count }
    end
  end

  context 'api repository user without update signatures rights' do
    before do
      kp = FactoryGirl.build(:key_pair)
      put :signatures, :id => @repository.id, :repository => {:public => kp.public, :secret => kp.secret}, :format => :json
    end
    it 'should not be able to perform signatures action' do
      response.should_not be_success
    end
    it 'ensures that signatures has not been updated' do
      @repository.key_pair.should be_nil
    end
  end

end

shared_examples_for 'api repository user without project manage rights' do
  context 'api repository user without add_project rights' do
    before { put :add_project, :id => @repository.id, :project_id => @project.id, :format => :json }
    it 'should not be able to perform add_project action' do
      response.should_not be_success
    end
    it 'ensures that project has not been added to repository' do
      @repository.projects.should_not include(@project)
    end
  end

  context 'api repository user without remove_project rights' do
    before do
      @repository.projects << @project
      delete :remove_project, :id => @repository.id, :project_id => @project.id, :format => :json
    end
    it 'should not be able to perform remove_project action' do
      response.should_not be_success
    end
    it 'ensures that project has not been removed from repository' do
      @repository.reload
      @repository.projects.should include(@project)
    end
  end
end


describe Api::V1::RepositoriesController do
  before(:each) do
    stub_symlink_methods
    stub_redis

    @platform = FactoryGirl.create(:platform)
    @repository = FactoryGirl.create(:repository, :platform =>  @platform)
    @personal_repository = FactoryGirl.create(:personal_repository)
    @project = FactoryGirl.create(:project)
    @another_user = FactoryGirl.create(:user)
  end

  context 'for guest' do
    it "should not be able to perform show action", :anonymous_access  => false do
      get :show, :id => @repository.id, :format => :json
      response.status.should == 401
    end

    if APP_CONFIG['anonymous_access']
      it_should_behave_like 'api repository user without reader rights for hidden platform'
      it_should_behave_like 'api repository user with show rights'
    end
    it_should_behave_like 'api repository user without writer rights'
    it_should_behave_like 'api repository user without project manage rights'
    it_should_behave_like 'api repository user without key_pair rights'

    it 'should not be able to perform projects action', :anonymous_access => false do
      get :projects, :id => @repository.id, :format => :json
      response.should_not be_success
    end
  end

  context 'for admin' do
    before(:each) do
      @admin = FactoryGirl.create(:admin)
      http_login(@admin)
    end

    it_should_behave_like 'api repository user with reader rights'
    it_should_behave_like 'api repository user with reader rights for hidden platform'
    it_should_behave_like 'api repository user with writer rights'
    it_should_behave_like 'api repository user without key_pair rights'
  end

  context 'for platform owner user' do
    before(:each) do
      @user = FactoryGirl.create(:user)
      http_login(@user)
      [@repository, @personal_repository].each do |repository|
        platform = repository.platform
        platform.owner = @user; platform.save
        repository.platform.relations.create!(:actor_type => 'User', :actor_id => @user.id, :role => 'admin')
      end
    end

    it_should_behave_like 'api repository user with reader rights'
    it_should_behave_like 'api repository user with reader rights for hidden platform'
    it_should_behave_like 'api repository user with writer rights'
    it_should_behave_like 'api repository user without key_pair rights'
  end

  context 'for user' do
    before(:each) do
      @user = FactoryGirl.create(:user)
      http_login(@user)
    end

    it_should_behave_like 'api repository user with reader rights'
    it_should_behave_like 'api repository user without reader rights for hidden platform'
    it_should_behave_like 'api repository user with show rights'
    it_should_behave_like 'api repository user without writer rights'
    it_should_behave_like 'api repository user without project manage rights'
    it_should_behave_like 'api repository user without key_pair rights'
  end

  context 'for member of repository' do
    before(:each) do
      @user = FactoryGirl.create(:user)
      @repository.add_member @user
      http_login @user
    end

    it_should_behave_like 'api repository user with reader rights'
    it_should_behave_like 'api repository user with reader rights for hidden platform'
    it_should_behave_like 'api repository user with show rights'
    it_should_behave_like 'api repository user with project manage rights'
    it_should_behave_like 'api repository user without writer rights'
    it_should_behave_like 'api repository user without key_pair rights'
  end

  context 'for system user' do
    before(:each) do
      @user = FactoryGirl.create(:user, :role => 'system')
      http_login(@user)
    end

    it 'should be able to perform key_pair action when repository has not keys' do
      get :key_pair, :id => @repository.id, :format => :json
      response.should be_success
    end

    it 'should be able to perform key_pair action when repository has keys' do
      FactoryGirl.create(:key_pair, :repository => @repository)
      get :key_pair, :id => @repository.id, :format => :json
      response.should be_success
    end

  end

end
