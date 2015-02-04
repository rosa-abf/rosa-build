require 'spec_helper'

describe AutocompletesController do
  before {stub_symlink_methods}

  context 'for user' do
    let(:user) { FactoryGirl.create(:user) }
    before do
      set_session_for user
    end

    it 'should be able to perform autocomplete_user_or_group action' do
      get :autocomplete_user_or_group
      response.should be_success
    end

    it 'should be able to perform autocomplete_user_uname action' do
      get :autocomplete_user_uname
      response.should be_success
    end

    context 'autocomplete_extra_build_list' do
      let(:build_list)  { FactoryGirl.create(:build_list, user: user) }
      let(:params)      { { :term         => build_list.id,
                            :platform_id  => build_list.save_to_platform_id } }

      it 'no data when build_list without container' do
        get :autocomplete_extra_build_list, params
        response.body.should == '[]'
      end

      it 'shows data when build_list with container' do
        build_list.update_column(:container_status, BuildList::BUILD_PUBLISHED)
        get :autocomplete_extra_build_list, params
        response.body.should_not == '[]'
      end
    end

    context 'autocomplete_extra_repositories' do
      let(:repository)  { FactoryGirl.create(:repository) }
      let(:params)      { { :term         => repository.platform.name,
                            :platform_id  => repository.platform_id } }

      before do
        repository.platform.add_member(user)
      end

      it 'no data when repository of main platform' do
        get :autocomplete_extra_repositories, params
        response.body.should == '[]'
      end

      it 'shows data when repository of personal platform' do
        Platform.update_all(platform_type: 'personal')
        get :autocomplete_extra_repositories, params
        response.body.should_not == '[]'
      end
    end

  end

  context 'for guest' do

    before do
      set_session_for(User.new)
    end

    [
      :autocomplete_user_or_group,
      :autocomplete_user_uname,
      :autocomplete_extra_build_list,
      :autocomplete_extra_repositories
    ].each do |action|
      it "should not be able to perform #{action} action" do
        get action
        response.should redirect_to(new_user_session_path)
      end
    end

  end
end
