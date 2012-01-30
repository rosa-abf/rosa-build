# -*- encoding : utf-8 -*-
require 'spec_helper'

shared_examples_for 'can subscribe' do
  it 'should be able to perform create action' do
    post :create, @create_params
    response.should redirect_to(project_issue_path(@project, @issue))
  end

  it 'should create subscribe object into db' do
    lambda{ post :create, @create_params }.should change{ Subscribe.count }.by(1)
  end
end

shared_examples_for 'can not subscribe' do
  it 'should not be able to perform create action' do
    post :create, @create_params
    response.should redirect_to(forbidden_path)
  end

  it 'should not create subscribe object into db' do
    lambda{ post :create, @create_params }.should change{ Subscribe.count }.by(0)
  end
end

shared_examples_for 'can unsubscribe' do
  it 'should be able to perform destroy action' do
    delete :destroy, @destroy_params

    response.should redirect_to([@project, @issue])
  end

  it 'should reduce subscribes count' do
    lambda{ delete :destroy, @destroy_params }.should change{ Subscribe.count }.by(-1)
  end
end

shared_examples_for 'can not unsubscribe' do
  it 'should not be able to perform destroy action' do
    delete :destroy, @destroy_params

    response.should redirect_to(forbidden_path)
  end

  it 'should not reduce subscribes count' do
    lambda{ delete :destroy, @destroy_params }.should change{ Subscribe.count }.by(0)
  end
end

describe SubscribesController do
  before(:each) do
    stub_rsync_methods

    @project = Factory(:project)
    @issue = Factory(:issue, :project_id => @project.id)

    @create_params = {:issue_id => @issue.serial_id, :project_id => @project.id}
    @destroy_params = {:issue_id => @issue.serial_id, :project_id => @project.id}

    any_instance_of(Project, :versions => ['v1.0', 'v2.0'])

    @request.env['HTTP_REFERER'] = project_issue_path(@project, @issue)
  end

  context 'for global admin user' do
    before(:each) do
      @user = Factory(:admin)
      set_session_for(@user)
      @project.relations.create!(:object_type => 'User', :object_id => @user.id, :role => 'admin')
      @destroy_params = @destroy_params.merge({:id => @user.id})
    end

    context 'subscribed' do
      before(:each) do
        ss = @issue.subscribes.build(:user => @user)
        ss.save!
      end

      it_should_behave_like 'can unsubscribe'
      it_should_behave_like 'can not subscribe'
    end

    context 'not subscribed' do
      it_should_behave_like 'can subscribe'
    end
  end

  context 'for simple user' do
    before(:each) do
      @user = Factory(:user)
      set_session_for(@user)
      @destroy_params = @destroy_params.merge({:id => @user.id})
    end

    context 'subscribed' do
      before(:each) do
        ss = @issue.subscribes.build(:user => @user)
        ss.save!
      end

      it_should_behave_like 'can unsubscribe'
      it_should_behave_like 'can not subscribe'
    end

    context 'not subscribed' do
      it_should_behave_like 'can subscribe'
    end
  end

end
