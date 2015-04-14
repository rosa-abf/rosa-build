require 'spec_helper'

def subscribe_to_commit
  Subscribe.subscribe_to_commit(project_id:         @project.id,
                                subscribeable_id:   @commit.id.hex,
                                subscribeable_type: @commit.class.name,
                                user_id:            @user.id)
end

shared_examples_for 'can subscribe' do
  it 'should be able to perform create action' do
    post :create, @create_params
    expect(response).to redirect_to(commit_path(@project, @commit))
  end

  it 'should create subscribe object into db' do
    expect { post :create, @create_params }.to change(Subscribe, :count).by(1)
  end
end

shared_examples_for 'can not subscribe' do
  it 'should not be able to perform create action' do
    post :create, @create_params
    expect(response).to redirect_to(commit_path(@project, @commit))
  end

  it 'should not create subscribe object into db' do
    expect { post :create, @create_params }.to_not change(Subscribe, :count)
  end
end

shared_examples_for 'can unsubscribe' do
  it 'should be able to perform destroy action' do
    delete :destroy, @destroy_params
    expect(response).to redirect_to(commit_path(@project, @commit))
  end

  it 'should reduce subscribes count' do
    delete :destroy, @destroy_params
    expect(Subscribe.subscribed_to_commit?(@project, @user, @commit)).to be_falsy
  end
end

shared_examples_for 'can not unsubscribe' do
  it 'should not be able to perform destroy action' do
    delete :destroy, @destroy_params

    expect(response).to redirect_to(commit_path(@project, @commit))
  end

  it 'should not reduce subscribes count' do
    expect { delete :destroy, @destroy_params }.to_not change(Subscribe, :count)
  end
end

describe Projects::CommitSubscribesController, type: :controller do
  before(:each) do
    stub_symlink_methods

    @project = FactoryGirl.create(:project_with_commit)
    @commit = @project.repo.commits.first

    @create_params =  { commit_id: @commit.sha, name_with_owner: @project.name_with_owner }
    @destroy_params = { commit_id: @commit.sha, name_with_owner: @project.name_with_owner }

    allow_any_instance_of(Project).to receive(:versions).and_return(%w(v1.0 v2.0))
  end

  context 'for global admin user' do
    before(:each) do
      @user = FactoryGirl.create(:admin)
      set_session_for(@user)
    end

    context 'subscribed' do
      before(:each) { subscribe_to_commit }
      it_should_behave_like 'can unsubscribe'
      it_should_behave_like 'can not subscribe'
    end

    context 'not subscribed' do
      it_should_behave_like 'can subscribe'
    end
  end

  context 'for simple user' do
    before(:each) do
      @user = FactoryGirl.create(:user)
      set_session_for(@user)
    end

    context 'subscribed' do
      before(:each) { subscribe_to_commit }

      it_should_behave_like 'can unsubscribe'
      it_should_behave_like 'can not subscribe'
    end

    context 'not subscribed' do
      it_should_behave_like 'can subscribe'
    end
  end

  context 'for guest' do
    before(:each) { set_session_for(User.new) }

    it 'should not be able to perform create action' do
      post :create, @create_params
      expect(response).to redirect_to(new_user_session_path)
    end

    it 'should not be able to perform destroy action' do
      delete :destroy, @destroy_params
      expect(response).to redirect_to(new_user_session_path)
    end
  end
end
