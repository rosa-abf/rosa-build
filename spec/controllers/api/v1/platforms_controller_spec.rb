require 'spec_helper'

shared_examples_for 'api platform user with reader rights' do
  include_examples "api platform user with show rights"

  it 'should be able to perform index action' do
    get :index, format: :json
    expect(response).to render_template(:index)
  end

  it 'should be able to perform members action' do
    get :members, id: @platform.id, format: :json
    expect(response).to render_template(:members)
  end

end

shared_examples_for 'api platform user with owner rights' do

  context 'api platform user with update rights' do
    before do
      put :update, platform: { description: 'new description' }, id: @platform.id, format: :json
    end

    it 'should be able to perform update action' do
      expect(response).to be_success
    end
    it 'ensures that platform has been updated' do
      expect(@platform.reload.description).to eq 'new description'
    end
  end

  context 'api platform user with destroy rights for main platforms only' do
    it 'should be able to perform destroy action for main platform' do
      delete :destroy, id: @platform.id, format: :json
      expect(response).to be_success
    end
    it 'ensures that main platform has been destroyed' do
      expect do
        delete :destroy, id: @platform.id, format: :json
      end.to change(Platform, :count).by(-1)
    end
    it 'should not be able to perform destroy action for personal platform' do
      delete :destroy, id: @personal_platform.id, format: :json
      expect(response).to_not be_success
    end
    it 'ensures that personal platform has not been destroyed' do
      expect do
        delete :destroy, id: @personal_platform.id, format: :json
      end.to_not change(Platform, :count)
    end
  end
end

shared_examples_for 'api platform user without owner rights' do
  context 'api platform user without update rights' do
    before do
      put :update, platform: { description: 'new description' }, id: @platform.id, format: :json
    end

    it 'should not be able to perform update action' do
      expect(response).to_not be_success
    end
    it 'ensures that platform has not been updated' do
      expect(@platform.reload.description).to_not eq 'new description'
    end
  end

  context 'api platform user without destroy rights' do
    it 'should not be able to perform destroy action for main platform' do
      delete :destroy, id: @platform.id, format: :json
      expect(response).to_not be_success
    end
    it 'ensures that main platform has not been destroyed' do
      expect do
        delete :destroy, id: @platform.id, format: :json
      end.to_not change(Platform, :count)
    end
    it 'should not be able to perform destroy action for personal platform' do
      delete :destroy, id: @personal_platform.id, format: :json
      expect(response).to_not be_success
    end
    it 'ensures that personal platform has not been destroyed' do
      expect do
        delete :destroy, id: @personal_platform.id, format: :json
      end.to_not change(Platform, :count)
    end
  end

end

shared_examples_for 'api platform user with member rights' do

  context 'api platform user with add_member rights' do
    let(:member) { FactoryGirl.create(:user) }
    before do
      put :add_member, member_id: member.id, type: 'User', id: @platform.id, format: :json
    end

    it 'should be able to perform add_member action' do
      expect(response).to be_success
    end
    it 'ensures that new member has been added to platform' do
      expect(@platform.members).to include(member)
    end
  end

  context 'api platform user with remove_member rights' do
    let(:member) { FactoryGirl.create(:user) }
    before do
      @platform.add_member(member)
      delete :remove_member, member_id: member.id, type: 'User', id: @platform.id, format: :json
    end

    it 'should be able to perform remove_member action' do
      expect(response).to be_success
    end
    it 'ensures that member has been removed from platform' do
      expect(@platform.members).to_not include(member)
    end
  end

end

shared_examples_for 'api platform user without member rights' do

  context 'api platform user without add_member rights' do
    let(:member) { FactoryGirl.create(:user) }
    before do
      put :add_member, member_id: member.id, type: 'User', id: @platform.id, format: :json
    end

    it 'should not be able to perform add_member action' do
      expect(response).to_not be_success
    end
    it 'ensures that new member has not been added to platform' do
      expect(@platform.members).to_not include(member)
    end
  end

  context 'api platform user without remove_member rights' do
    let(:member) { FactoryGirl.create(:user) }
    before do
      @platform.add_member(member)
      delete :remove_member, member_id: member.id, type: 'User', id: @platform.id, format: :json
    end

    it 'should be able to perform update action' do
      expect(response).to_not be_success
    end
    it 'ensures that member has not been removed from platform' do
      expect(@platform.members).to include(member)
    end
  end

end

shared_examples_for 'api platform user without global admin rights' do
  context 'should not be able to perform clear action' do
    it 'for personal platform' do
      put :clear, id: @personal_platform.id, format: :json
      expect(response).to_not be_success
    end
    it 'for main platform' do
      put :clear, id: @platform.id, format: :json
      expect(response).to_not be_success
    end
  end

  [:create, :clone].each do |action|
    context "api platform user without #{action} rights" do
      it "should not be able to perform #{action} action" do
        post action, clone_or_create_params
        expect(response).to_not be_success
      end
      it "ensures that platform has not been #{action}d" do
        expect do
          post action, clone_or_create_params
        end.to_not change(Platform, :count)
      end
    end
  end
end

shared_examples_for 'api platform user with reader rights for hidden platform' do
  before(:each) do
    @platform.update_column(:visibility, 'hidden')
  end

  it_should_behave_like 'api platform user with show rights'
end

shared_examples_for 'api platform user without reader rights for hidden platform' do
  before(:each) do
    @platform.update_column(:visibility, 'hidden')
  end

  [:show, :members].each do |action|
    it "should not be able to perform #{ action } action" do
      get action, id: @platform.id, format: :json
      expect(response.body).to eq({"message" => "Access violation to this page!"}.to_json)
    end
  end
end

shared_examples_for "api platform user with show rights" do
  it 'should be able to perform show action' do
    get :show, id: @platform.id, format: :json
    expect(response).to render_template(:show)
  end

  it 'should be able to perform platforms_for_build action' do
    get :platforms_for_build, format: :json
    expect(response).to render_template(:index)
  end
end

describe Api::V1::PlatformsController, type: :controller do
  let(:clone_or_create_params) do
    { id: @platform.id,
      platform: { description: 'new description', name: 'new_name',
                  owner_id: @user.id, distrib_type: APP_CONFIG['distr_types'].first, default_branch: 'new_name' }, format: :json }
  end
  before do
    stub_symlink_methods

    @platform = FactoryGirl.create(:platform, visibility: 'open')
    @personal_platform = FactoryGirl.create(:platform, platform_type: 'personal')
    @user = FactoryGirl.create(:user)
  end

  context 'for guest' do

    it "should not be able to perform index action" do
      get :index, format: :json
      expect(response.status).to eq 401
    end

    it "should not be able to perform platforms_for_build action", :anonymous_access  => false do
      get :platforms_for_build, format: :json
      expect(response.status).to eq 401
    end

    it "should not be able to perform show action", :anonymous_access  => false do
      get :show, id: @platform, format: :json
      expect(response.status).to eq 401
    end


    it 'should be able to perform members action', :anonymous_access  => true do
      get :members, id: @platform.id, format: :json
      expect(response).to render_template(:members)
    end

    it_should_behave_like 'api platform user with show rights' if APP_CONFIG['anonymous_access']
    it_should_behave_like 'api platform user without reader rights for hidden platform' if APP_CONFIG['anonymous_access']
    it_should_behave_like 'api platform user without member rights'
    it_should_behave_like 'api platform user without owner rights'
    it_should_behave_like 'api platform user without global admin rights'


    context 'perform allowed action' do
      it 'ensures that status 200 if platform empty' do
        get :allowed
        expect(response).to be_success
      end

      it 'ensures that status 403 if platform does not exist' do
        get :allowed, path: "/rosa-server/repository/SRPMS/base/release/repodata/"
        expect(response.status).to eq 403
      end

      it 'ensures that status 200 if platform open' do
        get :allowed, path: "/#{@platform.name}/repository/SRPMS/base/release/repodata/"
        expect(response).to be_success
      end

      context 'for hidden platform' do
        before { @platform.change_visibility }

        it 'ensures that status 403 if no token' do
          get :allowed, path: "/#{@platform.name}/repository/SRPMS/base/release/repodata/"
          expect(response.status).to eq 403
        end

        it 'ensures that status 403 if no token and a lot of "/"' do
          get :allowed, path: "///#{@platform.name}///repository/SRPMS/base/release/repodata/"
          expect(response.status).to eq 403
        end

        it 'ensures that status 200 if token correct and a lot of "/"' do
          token = FactoryGirl.create(:platform_token, subject: @platform)
          http_login token.authentication_token, ''
          get :allowed, path: "///#{@platform.name}///repository/SRPMS/base/release/repodata/"
          expect(response).to be_success
        end

        it 'ensures that status 403 on access to root of platform if no token' do
          get :allowed, path: "///#{@platform.name}"
          expect(response.status).to eq 403
        end

        it 'ensures that status 200 on access to root of platform if token correct' do
          token = FactoryGirl.create(:platform_token, subject: @platform)
          http_login token.authentication_token, ''
          get :allowed, path: "///#{@platform.name}"
          expect(response).to be_success
        end

        it 'ensures that status 403 if wrong token' do
          http_login 'KuKu', ''
          get :allowed, path: "/#{@platform.name}/repository/SRPMS/base/release/repodata/"
          expect(response.status).to eq 403
        end

        it 'ensures that status 200 if token correct' do
          token = FactoryGirl.create(:platform_token, subject: @platform)
          http_login token.authentication_token, ''
          get :allowed, path: "/#{@platform.name}/repository/SRPMS/base/release/repodata/"
          expect(response).to be_success
        end

        it 'ensures that status 403 if token correct but blocked' do
          token = FactoryGirl.create(:platform_token, subject: @platform)
          token.block
          http_login token.authentication_token, ''
          get :allowed, path: "/#{@platform.name}/repository/SRPMS/base/release/repodata/"
          expect(response.status).to eq 403
        end

        it 'ensures that status 200 if user token correct and user has ability to read platform' do
          http_login @platform.owner.authentication_token, ''
          get :allowed, path: "/#{@platform.name}/repository/SRPMS/base/release/repodata/"
          expect(response).to be_success
        end

        it 'ensures that status 403 if user token correct but user has no ability to read platform' do
          user = FactoryGirl.create(:user)
          http_login user.authentication_token, ''
          get :allowed, path: "/#{@platform.name}/repository/SRPMS/base/release/repodata/"
          expect(response.status).to eq 403
        end
      end
    end
  end

  context 'for global admin' do
    before do
      @admin = FactoryGirl.create(:admin)
      http_login(@admin)
    end

    it_should_behave_like 'api platform user with reader rights'
    it_should_behave_like 'api platform user with reader rights for hidden platform'
    it_should_behave_like 'api platform user with member rights'
    it_should_behave_like 'api platform user with owner rights'

    [:clone, :create].each do |action|
      context "with #{action} rights" do
        before { clone_or_create_params[:platform][:owner_id] = @admin.id }

        it "should be able to perform #{action} action" do
          post action, clone_or_create_params
          expect(response).to be_success
        end
        it "ensures that platform has been #{action}d" do
          expect do
            post action, clone_or_create_params
          end.to change(Platform, :count).by(1)
        end
      end
    end

  end

  context 'for owner user' do
    before do
      http_login(@user)
      @platform.owner = @user; @platform.save
      create_relation(@platform, @user, 'admin')
    end

    it_should_behave_like 'api platform user with reader rights'
    it_should_behave_like 'api platform user with reader rights for hidden platform'
    it_should_behave_like 'api platform user with member rights'
    it_should_behave_like 'api platform user with owner rights'
    it_should_behave_like 'api platform user without global admin rights'
  end

  context 'for member of platform' do
    before do
      http_login(@user)
      @platform.add_member(@user)
      @personal_platform.add_member(@user)
    end

    context 'perform index action with type param' do
      render_views
      %w(main personal).each do |type|
        it "ensures that filter by type = #{type} returns true result" do
          get :index, format: :json, type: type
          types = JSON.parse(response.body)['platforms'].map{ |p| p['platform_type'] }.uniq
          expect(types).to eq [type]
        end
      end
    end

    it_should_behave_like 'api platform user with reader rights'
    it_should_behave_like 'api platform user with reader rights for hidden platform'
    it_should_behave_like 'api platform user with member rights'
    it_should_behave_like 'api platform user without owner rights'
    it_should_behave_like 'api platform user without global admin rights'
  end

  context 'for member of repository' do
    before do
      http_login(@user)
      repository = FactoryGirl.create(:repository, platform: @platform)
      repository.add_member(@user)
      personal_repository = FactoryGirl.create(:repository, platform: @personal_platform)
      personal_repository.add_member(@user)
    end

    context 'perform index action with type param' do
      render_views
      %w(main personal).each do |type|
        it "ensures that filter by type = #{type} returns true result" do
          get :index, format: :json, type: type
          types = JSON.parse(response.body)['platforms'].map{ |p| p['platform_type'] }.uniq
          expect(types).to eq [type]
        end
      end
    end

    it 'should not be able to perform members action for hidden platform' do
      @platform.update_column(:visibility, 'hidden')
      get :members, id: @platform.id, format: :json
      expect(response.status).to eq 403
    end
    it_should_behave_like 'api platform user with reader rights'
    it_should_behave_like 'api platform user with reader rights for hidden platform'
    it_should_behave_like 'api platform user without member rights'
    it_should_behave_like 'api platform user without owner rights'
    it_should_behave_like 'api platform user without global admin rights'
  end

  context 'for simple user' do
    before do
      http_login(@user)
    end

    it_should_behave_like 'api platform user with reader rights'
    it_should_behave_like 'api platform user without reader rights for hidden platform'
    it_should_behave_like 'api platform user without member rights'
    it_should_behave_like 'api platform user without owner rights'
    it_should_behave_like 'api platform user without global admin rights'
  end
end
