require 'spec_helper'

shared_examples_for 'show build list via api' do
  it 'should be able to perform show action' do
    get :show, @show_params
    expect(response).to render_template("api/v1/build_lists/show")
  end

  it 'should be able to perform index action' do
    get :index, format: :json
    expect(response).to render_template("api/v1/build_lists/index")
  end
end

shared_examples_for 'not show build list via api' do
  it 'should not be able to perform show action' do
    get :show, @show_params
    expect(response.body).to eq({"message" => "Access violation to this page!"}.to_json)
  end

  pending 'should not be able to perform index action' do
    get :index, format: :json
    expect(response.body).to eq({"message" => "Access violation to this page!"}.to_json)
  end
end

shared_examples_for 'create build list via api' do

  it 'should create one more build list' do
    expect { post :create, @create_params }.to change(BuildList, :count).by(1)
  end

  it 'should return 200 response code' do
    post :create, @create_params
    expect(response).to be_success
  end

  it 'should save correct commit_hash for branch based build' do
    post :create, @create_params
    expect(@project.build_lists.last.commit_hash).to eq @params[:commit_hash]
  end

  it 'should save correct commit_hash for tag based build' do
    system("cd #{@project.repo.path} && git tag 4.7.5.3") # TODO REDO through grit
    post :create, @create_params
    expect(@project.build_lists.last.commit_hash).to eq @params[:commit_hash]
  end

  it 'should not create without existing commit hash in project' do
    expect {
      post :create, @create_params.deep_merge(build_list: {commit_hash: 'wrong'})
    }.to change{@project.build_lists.count}.by(0)
  end

  it 'should not create without existing arch' do
    expect {
      post :create, @create_params.deep_merge(build_list: {arch_id: -1})
    }.to change{@project.build_lists.count}.by(0)
  end

  it 'should not create without existing save_to_platform' do
    expect {
      post :create, @create_params.deep_merge(build_list: {save_to_platform_id: -1, save_to_repository_id: -1})
    }.to change{@project.build_lists.count}.by(0)
  end

  it 'should not create without existing save_to_repository' do
    expect {
      post :create, @create_params.deep_merge(build_list: {save_to_repository_id: -1})
    }.to change{@project.build_lists.count}.by(0)
  end
end

shared_examples_for 'not create build list via api' do
  it 'should not be able to perform create action' do
    post :create, @create_params
    expect(response.body).to eq({"message" => "Access violation to this page!"}.to_json)
  end

  it 'should not create one more build list' do
    expect { post :create, @create_params }.to change(BuildList, :count).by(0)
  end

  it 'should return 403 response code' do
    post :create, @create_params
    expect(response.status).to eq 403
  end
end

shared_examples_for 'validation error via build list api' do |message|
  it 'should return 422 response code and correct json error message' do
    expect(response.status).to eq 422
    expect(response.body).to eq({ build_list: {id: nil, message: message} }.to_json)
  end
end

describe Api::V1::BuildListsController, type: :controller do
  before do
    stub_symlink_methods
    allow_any_instance_of(BuildList).to receive(:valid_branch_for_publish?).and_return(true)
  end

  context 'create and update abilities' do
    context 'for user' do
      before do
        @build_list = FactoryGirl.create(:build_list)
        @params = @build_list.attributes.symbolize_keys
        @project = @build_list.project
        @platform = @build_list.save_to_platform
        #@platform = FactoryGirl.create(:platform_with_repos)

        @user = FactoryGirl.create(:user)
        @owner_user = @project.owner
        @member_user = FactoryGirl.create(:user)
        create_relation(@project, @member_user, 'reader')
        create_relation @build_list.save_to_platform, @owner_user, 'admin' # Why it's really need it??

        # Create and show params:
        @create_params = {build_list: @build_list.attributes.symbolize_keys.merge(:qwerty=>'!')} # wrong parameter
        @create_params = @create_params.merge(arches: [@params[:arch_id]], build_for_platform_id: @platform.id, format: :json)
        allow_any_instance_of(Project).to receive(:versions).and_return(%w(v1.0 v2.0))

        http_login(@user)
      end

      context 'do rerun_tests' do
        def do_rerun_tests
          put :rerun_tests, id: @build_list, format: :json
        end

        before do
          allow_any_instance_of(BuildList).to receive(:can_rerun_tests?).and_return(true)
        end

        context 'if user is project owner' do
          before { http_login(@owner_user) }

          it 'reruns tests' do
            expect_any_instance_of(BuildList).to receive(:rerun_tests).and_return(true)
            do_rerun_tests
            expect(response.body).to eq({ build_list: {id: @build_list.id, message: I18n.t('layout.build_lists.rerun_tests_success')} }.to_json)
            expect(response).to be_success
          end

          context 'returns an error if the can not rerun_tests' do
            before do
              allow_any_instance_of(BuildList).to receive(:rerun_tests).and_return(false)
              do_rerun_tests
            end

            it_should_behave_like 'validation error via build list api', I18n.t('layout.build_lists.rerun_tests_fail')
          end
        end

        it 'returns an error if user is not project owner' do
          expect_any_instance_of(BuildList).to_not receive(:rerun_tests)
          do_rerun_tests
          expect(response.body).to eq({"message" => "Access violation to this page!"}.to_json)
        end
      end

      context "do cancel" do
        def do_cancel
          put :cancel, id: @build_list, format: :json
        end

        context 'if user is project owner' do
          before {http_login(@owner_user)}

          it 'cancels build' do
            expect_any_instance_of(BuildList).to receive(:cancel).and_return(true)
            do_cancel
            expect(response.body).to eq({ build_list: {id: @build_list.id, message: I18n.t('layout.build_lists.cancel_success')} }.to_json)
            expect(response).to be_success
          end

          context 'returns an error if the can not cancel' do
            before do
              allow_any_instance_of(BuildList).to receive(:cancel).and_return(false)
              do_cancel
            end

            it_should_behave_like 'validation error via build list api', I18n.t('layout.build_lists.cancel_fail')
          end
        end

        it 'returns an error if user is not project owner' do
          expect_any_instance_of(BuildList).to_not receive(:cancel)
          do_cancel
          expect(response.body).to eq({"message" => "Access violation to this page!"}.to_json)
        end
      end

      context "do create_container" do
        def do_create_container
          put :create_container, id: @build_list, format: :json
        end

        context 'if user is project owner' do
          before do
            http_login(@owner_user)
          end

          context "if it has :success status" do
            before do
              @build_list.update_column(:status, BuildList::SUCCESS)
              do_create_container
            end
            it "should return correct json message" do
              expect(response.body).to eq({ build_list: {id: @build_list.id, message: I18n.t('layout.build_lists.create_container_success')} }.to_json)
            end

            it 'should return 200 response code' do
              expect(response).to be_success
            end

            it "should create container" do
              expect(@build_list.reload.container_status).to eq BuildList::BUILD_PUBLISH
            end
          end

          context "if it has another status" do
            before do
              @build_list.update_column(:status, BuildList::BUILD_ERROR)
              do_create_container
            end

            it_should_behave_like 'validation error via build list api', I18n.t('layout.build_lists.create_container_fail')

            it "should not create container" do
              expect(@build_list.reload.container_status).to eq BuildList::WAITING_FOR_RESPONSE
            end
          end
        end

        context 'if user is not project owner' do
          before do
            @build_list.update_column(:status, BuildList::SUCCESS)
            do_create_container
          end

          it "should return access violation message" do
            expect(response.body).to eq({"message" => "Access violation to this page!"}.to_json)
          end

          it "should not create container" do
            expect(@build_list.reload.container_status).to eq BuildList::WAITING_FOR_RESPONSE
          end
        end
      end

      context 'do publish_into_testing' do
        def do_publish_into_testing
          put :publish_into_testing, id: @build_list, format: :json
        end

        context 'if user is project && platform owner' do
          before do
            http_login(@owner_user)
          end

          context "if it has :failed_publish status" do
            before do
              @build_list.update_column(:status, BuildList::FAILED_PUBLISH)
              do_publish_into_testing
            end
            it "should return correct json message" do
              expect(response.body).to eq({ build_list: {id: @build_list.id, message: I18n.t('layout.build_lists.publish_success')} }.to_json)
            end

            it 'should return 200 response code' do
              expect(response).to be_success
            end

            it "should change status of build list" do
              expect(@build_list.reload.status).to eq BuildList::BUILD_PUBLISH_INTO_TESTING
            end
          end

          context "if it has :build_published_into_testing status" do
            before do
              @build_list.update_column(:status, BuildList::BUILD_PUBLISHED_INTO_TESTING)
              do_publish_into_testing
            end

            it "should return correct json message" do
              expect(response.body).to eq({ build_list: {id: @build_list.id, message: I18n.t('layout.build_lists.publish_success')} }.to_json)
            end

            it 'should return 200 response code' do
              expect(response).to be_success
            end

            it "should change status of build list" do
              expect(@build_list.reload.status).to eq BuildList::BUILD_PUBLISH_INTO_TESTING
            end
          end

          context "if it has another status" do
            before do
              @build_list.update_column(:status, BuildList::BUILD_CANCELED)
              do_publish_into_testing
            end

            it "should return access violation message" do
              expect(response.body).to eq({"message" => "Access violation to this page!"}.to_json)
            end

            it "should not change status of build list" do
              expect(@build_list.reload.status).to eq BuildList::BUILD_CANCELED
            end
          end

        end

        context 'if user is not project owner' do

          context "if it has :build_published_into_testing status" do
            before do
              @build_list.update_column(:status, BuildList::BUILD_PUBLISHED_INTO_TESTING)
              do_publish_into_testing
            end

            it 'should not be able to perform create action' do
              expect(response.body).to eq({"message" => "Access violation to this page!"}.to_json)
            end

            it 'should return 403 response code' do
              expect(response.status).to eq 403
            end

            it "should not change status of build list" do
              expect(@build_list.reload.status).to eq BuildList::BUILD_PUBLISHED_INTO_TESTING
            end
          end

          context "if it has :failed_publish status" do
            before do
              @build_list.update_column(:status, BuildList::FAILED_PUBLISH_INTO_TESTING)
              do_publish_into_testing
            end
            it "should return access violation message" do
              expect(response.body).to eq({"message" => "Access violation to this page!"}.to_json)
            end

            it "should not change status of build list" do
              expect(@build_list.reload.status).to eq BuildList::FAILED_PUBLISH_INTO_TESTING
            end
          end
        end
      end

      context "do publish" do
        def do_publish
          put :publish, id: @build_list, format: :json
        end

        context 'if user is project && platform owner' do
          before do
            http_login(@owner_user)
          end

          context "if it has :failed_publish status" do
            before do
              @build_list.update_column(:status, BuildList::FAILED_PUBLISH)
              do_publish
            end
            it "should return correct json message" do
              expect(response.body).to eq({ build_list: {id: @build_list.id, message: I18n.t('layout.build_lists.publish_success')} }.to_json)
            end

            it 'should return 200 response code' do
              expect(response).to be_success
            end

            it "should change status of build list" do
              expect(@build_list.reload.status).to eq BuildList::BUILD_PUBLISH
            end
          end

          context "if it has :published status" do
            before do
              @build_list.update_column(:status, BuildList::BUILD_PUBLISHED)
              do_publish
            end

            it "should return correct json message" do
              expect(response.body).to eq({ build_list: {id: @build_list.id, message: I18n.t('layout.build_lists.publish_success')} }.to_json)
            end

            it 'should return 200 response code' do
              expect(response).to be_success
            end

            it "should change status of build list" do
              expect(@build_list.reload.status).to eq BuildList::BUILD_PUBLISH
            end
          end

          context "if it has another status" do
            before do
              @build_list.update_column(:status, BuildList::BUILD_CANCELED)
              do_publish
            end

            it "should return access violation message" do
              expect(response.body).to eq({"message" => "Access violation to this page!"}.to_json)
            end

            it "should not change status of build list" do
              expect(@build_list.reload.status).to eq BuildList::BUILD_CANCELED
            end
          end

          context "if it has been builded on old core" do
            before do
              @build_list.update_column(:status, BuildList::FAILED_PUBLISH)
              @build_list.update_column(:new_core, false)
              do_publish
            end
            it "should return access violation message" do
              expect(response.body).to eq({"message" => "Access violation to this page!"}.to_json)
            end

            it "should not change status of build list" do
              expect(@build_list.reload.status).to eq BuildList::FAILED_PUBLISH
            end
          end
        end

        context 'if user is not project owner' do

          context "if it has :published status" do
            before do
              @build_list.update_column(:status, BuildList::BUILD_PUBLISHED)
              do_publish
            end

            it 'should not be able to perform create action' do
              expect(response.body).to eq({"message" => "Access violation to this page!"}.to_json)
            end

            it 'should return 403 response code' do
              expect(response.status).to eq 403
            end

            it "should not change status of build list" do
              expect(@build_list.reload.status).to eq BuildList::BUILD_PUBLISHED
            end
          end

          context "if it has :failed_publish status" do
            before do
              @build_list.update_column(:status, BuildList::FAILED_PUBLISH)
              do_publish
            end
            it "should return access violation message" do
              expect(response.body).to eq({"message" => "Access violation to this page!"}.to_json)
            end

            it "should not change status of build list" do
              expect(@build_list.reload.status).to eq BuildList::FAILED_PUBLISH
            end
          end
        end
      end

      context "do reject_publish" do
        before do
          allow_any_instance_of(BuildList).to receive(:current_duration).and_return(100)
          @build_list.save_to_repository.update_column(:publish_without_qa, false)
        end

        def do_reject_publish
          put :reject_publish, id: @build_list, format: :json
        end

        context 'if user is project owner' do
          before do
            http_login(@owner_user)
            @build_list.update_column(:status, BuildList::SUCCESS)
            @build_list.save_to_platform.update_column(:released, true)
            do_reject_publish
          end

          context "if it has :success status" do
            it "should return correct json message" do
              expect(response.body).to eq({ build_list: {id: @build_list.id, message: I18n.t('layout.build_lists.reject_publish_success')} }.to_json)
            end

            it 'should return 200 response code' do
              expect(response).to be_success
            end

            it "should reject publish build list" do
              expect(@build_list.reload.status).to eq BuildList::REJECTED_PUBLISH
            end
          end

          context "if it has another status" do
            before do
              @build_list.update_column(:status, BuildList::BUILD_CANCELED)
              do_reject_publish
            end

            it_should_behave_like 'validation error via build list api', I18n.t('layout.build_lists.reject_publish_fail')

            it "should not change status of build list" do
              expect(@build_list.reload.status).to eq BuildList::BUILD_CANCELED
            end
          end
        end

        context 'if user is not project owner' do
          before do
            @build_list.update_column(:status, BuildList::SUCCESS)
            @build_list.save_to_platform.update_column(:released, true)
            do_reject_publish
          end

          it "should return access violation message" do
            expect(response.body).to eq({"message" => "Access violation to this page!"}.to_json)
          end

          it "should not change status of build list" do
            do_reject_publish
            expect(@build_list.reload.status).to eq BuildList::SUCCESS
          end
        end

        context 'if user is project reader' do
          before do
            @another_user = FactoryGirl.create(:user)
            @build_list.update_column(:status, BuildList::SUCCESS)
            @build_list.save_to_repository.update_column(:publish_without_qa, true)
            Collaborator.create(actor_type: 'User', actor_id: @another_user.id, role: 'reader', project: @build_list.project)

            http_login(@another_user)
            do_reject_publish
          end

          it "should return access violation message" do
            expect(response.body).to eq({"message" => "Access violation to this page!"}.to_json)
          end

          it "should not change status of build list" do
            do_reject_publish
            expect(@build_list.reload.status).to eq BuildList::SUCCESS
          end
        end

        context 'if user is project writer' do
          before do
            @another_user = FactoryGirl.create(:user)
            @build_list.update_column(:status, BuildList::SUCCESS)
            @build_list.save_to_repository.update_column(:publish_without_qa, true)
            create_relation(@build_list.project, @another_user, 'writer')
            http_login(@another_user)
            do_reject_publish
          end

          it "should return correct json message" do
            expect(response.body).to eq({ build_list: {id: @build_list.id, message: I18n.t('layout.build_lists.reject_publish_success')} }.to_json)
          end

          it 'should return 200 response code' do
            expect(response).to be_success
          end

          it "should reject publish build list" do
            expect(@build_list.reload.status).to eq BuildList::REJECTED_PUBLISH
          end
        end
      end

      context 'for open project' do
        it_should_behave_like 'not create build list via api'

        context 'if user is project owner' do
          before {http_login(@owner_user)}
          it_should_behave_like 'create build list via api'

          context 'no ability to read build_for_platform' do
            before do
              repository = FactoryGirl.create(:repository)
              repository.platform.change_visibility
              Platform.where(id: @platform.id).update_all(platform_type: 'personal')
              @create_params[:build_list].merge!({
                :include_repos          => [repository.id],
                :build_for_platform_id  => repository.platform_id
              })
            end
            it_should_behave_like 'not create build list via api'
          end

        end

        context 'if user is project read member' do
          before {http_login(@member_user)}
          it_should_behave_like 'not create build list via api'
        end
      end

      context 'for hidden project' do
        before do
          @project.update_column(:visibility, 'hidden')
        end

        it_should_behave_like 'not create build list via api'

        context 'if user is project owner' do
          before {http_login(@owner_user)}

          it_should_behave_like 'create build list via api'
        end

        context 'if user is project read member' do
          before {http_login(@member_user)}
          it_should_behave_like 'not create build list via api'
        end
      end
    end

    context 'for group' do
      before do
        @build_list = FactoryGirl.create(:build_list)
        @params = @build_list.attributes.symbolize_keys
        @project = @build_list.project
        @platform = @build_list.save_to_platform

        stub_symlink_methods
        @user = FactoryGirl.create(:user)
        @owner_user = FactoryGirl.create(:user)
        @member_user = FactoryGirl.create(:user)

        # Create and show params:
        @create_params = {build_list: @build_list.attributes.symbolize_keys}
        @create_params = @create_params.merge(arches: [@params[:arch_id]], build_for_platform_id: @platform.id, format: :json)
        allow_any_instance_of(Project).to receive(:versions).and_return(%w(v1.0 v2.0))

        # Groups:
        @owner_group = FactoryGirl.create(:group, owner: @owner_user)
        @member_group = FactoryGirl.create(:group)
        create_actor_relation(@member_group, @member_user, 'reader')

        @group = FactoryGirl.create(:group)
        @user = FactoryGirl.create(:user)
        create_actor_relation(@group, @user, 'reader')

        old_path = @project.path
        @project.owner = @owner_group
        @project.save
        # Move GIT repo into new folder
        system "mkdir -p #{@project.path} && mv -f #{old_path}/* #{@project.path}/"

        create_relation(@project, @member_group, 'reader')
        create_relation(@project, @owner_group, 'admin')
        create_relation(@build_list.save_to_platform, @owner_group, 'admin') # Why it's really need it??
        create_relation(@build_list.save_to_platform, @member_group, 'reader')  # Why it's really need it??

        http_login(@user)
      end

      context 'for open project' do
        it_should_behave_like 'not create build list via api'

        context 'if user is group owner' do
          before {http_login(@owner_user)}
          it_should_behave_like 'create build list via api'
        end

        context 'if user is group read member' do
          before {http_login(@member_user)}
          it_should_behave_like 'not create build list via api'
        end
      end

      context 'for hidden project' do
        before do
          @build_list.project.update_column(:visibility, 'hidden')
        end

        it_should_behave_like 'not create build list via api'

        context 'if user is group owner' do
          before {http_login(@owner_user)}
          it_should_behave_like 'create build list via api'
        end

        context 'if user is group read member' do
          before {http_login(@member_user)}
          it_should_behave_like 'not create build list via api'
        end
      end

    end
  end

  context 'read and accessible abilities' do
    before do
      @user = FactoryGirl.create(:user)

      # Build Lists:
      @build_list1 = FactoryGirl.create(:build_list)

      @build_list2 = FactoryGirl.create(:build_list)
      @build_list2.project.update_column(:visibility, 'hidden')

      project = FactoryGirl.create(:project_with_commit, visibility: 'hidden', owner: @user)
      @build_list3 = FactoryGirl.create(:build_list_with_attaching_project, project: project)

      @build_list4 = FactoryGirl.create(:build_list)
      @build_list4.project.update_column(:visibility, 'hidden')
      create_relation(@build_list4.project, @user, 'reader')

      @filter_build_list1 = FactoryGirl.create(:build_list)
      @filter_build_list2 = FactoryGirl.create(:build_list)
      @filter_build_list3 = FactoryGirl.create(:build_list)
      @filter_build_list4 = FactoryGirl.create(:build_list, updated_at: (Time.now - 1.day),
                             project: @build_list3.project, save_to_platform: @build_list3.save_to_platform,
                             arch: @build_list3.arch)
    end

    context 'for guest' do
      it 'should be able to perform index action', anonymous_access: true do
        get :index, format: :json
        expect(response).to be_success
      end

      it 'should not be able to perform index action', anonymous_access: false do
        get :index, format: :json
        expect(response.status).to eq 401
      end
    end

    context 'for all build lists' do
      before { http_login(@user) }

      it 'should be able to perform index action' do
        get :index, format: :json
        expect(response).to be_success
      end

      it 'should show only accessible build_lists' do
        get :index, filter: { ownership: 'index' }, format: :json
        expect(assigns(:build_lists)).to include(@build_list1)
        expect(assigns(:build_lists)).to_not include(@build_list2)
        expect(assigns(:build_lists)).to include(@build_list3)
        expect(assigns(:build_lists)).to include(@build_list4)
        expect(assigns(:build_lists).count).to eq 7
      end
    end

    context 'filter' do
      before do
        http_login FactoryGirl.create(:admin)
      end

      it 'should filter by id' do
        get :index, filter: {id: @filter_build_list1.id, project_name: 'fdsfdf', any_other_field: 'do not matter'}, format: :json
        expect(assigns[:build_lists]).to include(@filter_build_list1)
        expect(assigns[:build_lists]).to_not include(@filter_build_list2)
        expect(assigns[:build_lists]).to_not include(@filter_build_list3)
      end

      it 'should filter by project_name' do
        get :index, filter: {project_name: @filter_build_list2.project.name, ownership: 'index'}, format: :json
        expect(assigns[:build_lists]).to_not include(@filter_build_list1)
        expect(assigns[:build_lists]).to include(@filter_build_list2)
        expect(assigns[:build_lists]).to_not include(@filter_build_list3)
      end

      it 'should filter by project_name and start_date' do
        get :index, filter: {project_name: @filter_build_list3.project.name, ownership: 'index',
                              :"updated_at_start(1i)" => @filter_build_list3.updated_at.year.to_s,
                              :"updated_at_start(2i)" => @filter_build_list3.updated_at.month.to_s,
                              :"updated_at_start(3i)" => @filter_build_list3.updated_at.day.to_s}, format: :json
        expect(assigns[:build_lists]).to_not include(@filter_build_list1)
        expect(assigns[:build_lists]).to_not include(@filter_build_list2)
        expect(assigns[:build_lists]).to include(@filter_build_list3)
        expect(assigns[:build_lists]).to_not include(@filter_build_list4)
      end

    end

    context "for user" do
      before do
        @build_list = FactoryGirl.create(:build_list)
        @params = @build_list.attributes.symbolize_keys
        @project = @build_list.project

        stub_symlink_methods
        @owner_user = @project.owner
        @member_user = FactoryGirl.create(:user)
        create_relation(@project, @member_user, 'reader')
        create_relation(@build_list.save_to_platform, @owner_user, 'admin') # Why it's really need it??

        # Show params:
        @show_params = {id: @build_list.id, format: :json}
      end

      context 'for open project' do
        context 'for simple user' do
          before {http_login(@user)}
          it_should_behave_like 'show build list via api'
        end

        context 'if user is project owner' do
          before {http_login(@owner_user)}
          it_should_behave_like 'show build list via api'
        end

        context 'if user is project read member' do
          before {http_login(@member_user)}
          it_should_behave_like 'show build list via api'
        end
      end

      context 'for hidden project' do
        before do
          @project.update_column(:visibility, 'hidden')
        end

        context 'for simple user' do
          before {http_login(@user)}
          it_should_behave_like 'not show build list via api'
        end

        context 'if user is project owner' do
          before {http_login(@owner_user)}
          it_should_behave_like 'show build list via api'
        end

        context 'if user is project read member' do
          before {http_login(@member_user)}
          it_should_behave_like 'show build list via api'
        end
      end
    end

    context "for group" do
      before do
        @platform = FactoryGirl.create(:platform_with_repos)
        @build_list = FactoryGirl.create(:build_list, save_to_platform: @platform)
        @project = @build_list.project
        @params = @build_list.attributes.symbolize_keys

        stub_symlink_methods
        @owner_user = @project.owner#FactoryGirl.create(:user)
        @member_user = FactoryGirl.create(:user)

        # Show params:
        @show_params = {id: @build_list.id, format: :json}

        # Groups:
        @owner_group = FactoryGirl.create(:group, owner: @owner_user)
        @member_group = FactoryGirl.create(:group)
        create_actor_relation(@member_group, @member_user, 'reader')
        @group = FactoryGirl.create(:group)
        create_actor_relation(@group, @user, 'reader')
        create_relation(@project, @member_group, 'reader')
      end

      context 'for open project' do
        context 'for simple user' do
          before {http_login(@user)}
          it_should_behave_like 'show build list via api'
        end

        context 'if user is group owner' do
          before {http_login(@owner_user)}
          it_should_behave_like 'show build list via api'
        end

        context 'if user is group read member' do
          before {http_login(@member_user)}
          it_should_behave_like 'show build list via api'
        end
      end

      context 'for hidden project' do
        before do
          @build_list.project.update_column(:visibility, 'hidden')
        end

        context 'for simple user' do
          before {http_login(@user)}
          it_should_behave_like 'not show build list via api'
        end

        context 'if user is group owner' do
          before { http_login(@owner_user) }
          it_should_behave_like 'show build list via api'
        end

        context 'if user is group read member' do
          before {http_login(@member_user)}
          it_should_behave_like 'show build list via api'
        end
      end
    end
  end
end
