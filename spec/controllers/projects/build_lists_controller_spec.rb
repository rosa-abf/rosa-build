require 'spec_helper'

describe Projects::BuildListsController, type: :controller do

  shared_examples_for 'show build list' do
    it 'should be able to perform show action' do
      get :show, @show_params
      expect(response).to be_success
    end

    it 'should be able to perform index action in project scope' do
      get :index, name_with_owner: @project.name_with_owner
      expect(response).to be_success
    end
  end

  shared_examples_for 'not show build list' do
    it 'should not be able to perform show action' do
      get :show, @show_params
      expect(response).to redirect_to(forbidden_url)
    end

    it 'should not be able to perform index action in project scope' do
      get :index, name_with_owner: @project.name_with_owner
      expect(response).to redirect_to(forbidden_url)
    end
  end

  shared_examples_for 'create build list' do
    before {
      @project.update_attribute(:repositories, @platform.repositories)
    }

    it 'should be able to perform new action' do
      get :new, name_with_owner: @project.name_with_owner
      expect(response).to render_template(:new)
    end

    it 'should be able to perform create action' do
      post :create, { name_with_owner: @project.name_with_owner }.merge(@create_params)
      expect(response).to redirect_to project_build_lists_path(@project)
    end

    it 'should save correct commit_hash for branch based build' do
      post :create, { name_with_owner: @project.name_with_owner }.merge(@create_params).deep_merge(build_list: { project_version: "master" })
      expect(@project.build_lists.last.commit_hash).to eq @project.repo.commits('master').first.id
    end

    it 'should save correct commit_hash for tag based build' do
      system("cd #{@project.repo.path} && git tag 4.7.5.3") # TODO REDO through grit
      post :create, { name_with_owner: @project.name_with_owner }.merge(@create_params).deep_merge(build_list: { project_version: "4.7.5.3" })
      expect(@project.build_lists.last.commit_hash).to eq @project.repo.commits('4.7.5.3').first.id
    end

    it 'should not be able to create with wrong project version' do
      expect do
        post :create, { name_with_owner: @project.name_with_owner }.merge(@create_params).deep_merge(build_list: { project_version: "wrong", commit_hash: nil })
      end.to_not change{ @project.build_lists.count }
    end

    it 'should not be able to create with wrong git hash' do
      expect do
        post :create, { name_with_owner: @project.name_with_owner }.merge(@create_params).deep_merge(build_list: { commit_hash: 'wrong' })
      end.to_not change{ @project.build_lists.count }
    end
  end

  shared_examples_for 'not create build list' do |skip_new = false|
    before {
      @project.update_attribute(:repositories, @platform.repositories)
    }

    it 'should not be able to perform new action' do
      get :new, name_with_owner: @project.name_with_owner
      expect(response).to redirect_to(forbidden_url)
    end unless skip_new

    it 'should not be able to perform create action' do
      post :create, { name_with_owner: @project.name_with_owner }.merge(@create_params)
      expect(response).to redirect_to(forbidden_url)
    end
  end

  before { stub_symlink_methods }

  context 'crud' do
    before do
      @platform = FactoryGirl.create(:platform_with_repos)
      @create_params = {
        build_list: {
          project_version: 'master',
          save_to_repository_id: @platform.repositories.first.id,
          update_type: 'security',
          include_repos: [@platform.repositories.first.id]
        },
        arches: [FactoryGirl.create(:arch).id],
        build_for_platforms: [@platform.id]
      }
      allow_any_instance_of(Project).to receive(:versions).and_return(%w(v1.0 v2.0))
    end

    context 'for guest' do
      it 'should be able to perform index action', anonymous_access: true do
        get :index
        expect(response).to be_success
      end

      it 'should not be able to perform index action', anonymous_access: false do
        get :index
        expect(response).to redirect_to(new_user_session_path)
      end

    end

    context 'for user' do
      before do
        allow_any_instance_of(BuildList).to receive(:current_duration).and_return(100)
        @build_list = FactoryGirl.create(:build_list)
        @project = @build_list.project
        @owner_user = @project.owner
        @member_user = FactoryGirl.create(:user)
        create_relation(@project, @member_user, 'reader')

        @user = FactoryGirl.create(:user)
        set_session_for(@user)
        @show_params = { name_with_owner: @project.name_with_owner, id: @build_list.id }
        @build_list.save_to_repository.update_column(:publish_without_qa, false)
        @request.env['HTTP_REFERER'] = build_list_path(@build_list)
      end

      context 'do rerun_tests' do
        def do_rerun_tests
          put :rerun_tests, id: @build_list
        end

        before do
          allow_any_instance_of(BuildList).to receive(:can_rerun_tests?).and_return(true)
        end

        context 'if user is project owner' do
          before { set_session_for(@owner_user) }

          it 'reruns tests' do
            expect_any_instance_of(BuildList).to receive(:rerun_tests).and_return(true)
            do_rerun_tests

            expect(response).to redirect_to(build_list_path(@build_list))
            expect(flash[:notice]).to match I18n.t('layout.build_lists.rerun_tests_success')
          end

          it 'returns an error if the can not rerun_tests' do
            allow_any_instance_of(BuildList).to receive(:rerun_tests).and_return(false)
            do_rerun_tests

            expect(response).to redirect_to(build_list_path(@build_list))
            expect(flash[:error]).to match I18n.t('layout.build_lists.rerun_tests_fail')
          end
        end

        it 'returns an error if user is not project owner' do
          expect_any_instance_of(BuildList).to_not receive(:rerun_tests)
          do_rerun_tests
          expect(response).to redirect_to(forbidden_url)
        end

        it 'returns an error if user is project reader' do
          @another_user = FactoryGirl.create(:user)
          Collaborator.create(actor_type: 'User', actor_id: @another_user.id, role: 'reader', project: @build_list.project)
          set_session_for(@another_user)

          expect_any_instance_of(BuildList).to_not receive(:rerun_tests)
          do_rerun_tests
          expect(response).to redirect_to(forbidden_url)
        end

        it 'reruns tests if user is project writer' do
          @writer_user = FactoryGirl.create(:user)
          create_relation(@build_list.project, @writer_user, 'writer')
          set_session_for(@writer_user)

          expect_any_instance_of(BuildList).to receive(:rerun_tests).and_return(true)
          do_rerun_tests
          expect(response).to redirect_to(build_list_path(@build_list))
          expect(flash[:notice]).to match I18n.t('layout.build_lists.rerun_tests_success')
        end

      end

      context "do reject_publish" do
        before {@build_list.save_to_repository.update_column(:publish_without_qa, true)}

        def do_reject_publish
          put :reject_publish, id: @build_list
        end

        context 'if user is project owner' do
          before do
            set_session_for(@owner_user)
            @build_list.update_column(:status, BuildList::SUCCESS)
            @build_list.save_to_platform.update_column(:released, true)
            do_reject_publish
          end

          context "if it has :success status" do
            it 'should return 302 response code' do
              expect(response.status).to eq 302
            end

            it "should reject publish build list" do
              expect(@build_list.reload.status).to eq BuildList::REJECTED_PUBLISH
            end
          end

          context "if it has another status" do
            before do
              @build_list.update_column(:status, BuildList::BUILD_ERROR)
              do_reject_publish
            end

            it "should not change status of build list" do
              expect(@build_list.reload.status).to eq BuildList::BUILD_ERROR
            end
          end
        end

        context 'if user is not project owner' do
          before do
            @build_list.update_column(:status, BuildList::SUCCESS)
            @build_list.save_to_platform.update_column(:released, true)
            do_reject_publish
          end

          it "should redirect to forbidden page" do
            expect(response).to redirect_to(forbidden_url)
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
            set_session_for(@another_user)
            do_reject_publish
          end

          it "should redirect to forbidden page" do
            expect(response).to redirect_to(forbidden_url)
          end

          it "should not change status of build list" do
            do_reject_publish
            expect(@build_list.reload.status).to eq BuildList::SUCCESS
          end
        end

        context 'if user is project writer' do
          before do
            @writer_user = FactoryGirl.create(:user)
            @build_list.update_column(:status, BuildList::SUCCESS)
            @build_list.save_to_repository.update_column(:publish_without_qa, true)
            create_relation(@build_list.project, @writer_user, 'writer')
            set_session_for(@writer_user)
            do_reject_publish
          end

          it 'should return 302 response code' do
            expect(response.status).to eq 302
          end

          it "should reject publish build list" do
            expect(@build_list.reload.status).to eq BuildList::REJECTED_PUBLISH
          end
        end
      end

      context 'for all build lists' do
        before do
          @build_list1 = FactoryGirl.create(:build_list)

          @build_list2 = FactoryGirl.create(:build_list)
          @build_list2.project.update_column(:visibility, 'hidden')

          project = FactoryGirl.create(:project_with_commit, visibility: 'hidden', owner: @user)
          @build_list3 = FactoryGirl.create(:build_list_with_attaching_project, project: project)

          @build_list4 = FactoryGirl.create(:build_list)
          @build_list4.project.update_column(:visibility, 'hidden')
          create_relation(@build_list4.project, @user, 'reader')
        end

        it 'should be able to perform index action' do
          get :index
          expect(response).to be_success
        end

        it 'should show only accessible build_lists' do
          get :index, filter: {ownership: 'everything'}, format: :json
          expect(assigns(:build_lists)).to include(@build_list1)
          expect(assigns(:build_lists)).to_not include(@build_list2)
          expect(assigns(:build_lists)).to include(@build_list3)
          expect(assigns(:build_lists)).to include(@build_list4)
        end
      end

      context 'for open project' do
        it_should_behave_like 'show build list'
        it_should_behave_like 'not create build list'

        context 'if user is project owner' do
          before {set_session_for(@owner_user)}
          it_should_behave_like 'show build list'
          it_should_behave_like 'create build list'

          context 'no ability to read build_for_platform' do
            before do
              repository = FactoryGirl.create(:repository)
              repository.platform.change_visibility
              Platform.where(id: @platform.id).update_all(platform_type: 'personal')
              @create_params[:build_list].merge!({include_repos: [repository.id]})
              @create_params[:build_for_platforms] = [repository.platform_id]
            end
            it_should_behave_like 'not create build list', true
          end

        end

        context 'if user is project read member' do
          before {set_session_for(@member_user)}
          it_should_behave_like 'show build list'
          it_should_behave_like 'not create build list'
        end
      end

      context 'for hidden project' do
        before do
          @project.visibility = 'hidden'
          @project.save
        end

        it_should_behave_like 'not show build list'
        it_should_behave_like 'not create build list'

        context 'if user is project owner' do
          before {set_session_for(@owner_user)}
          it_should_behave_like 'show build list'
          it_should_behave_like 'create build list'
        end

        context 'if user is project read member' do
          before {set_session_for(@member_user)}
          it_should_behave_like 'show build list'
          it_should_behave_like 'not create build list'
        end
      end
    end

    context 'for group' do
      before do

        @user = FactoryGirl.create(:user)
        set_session_for(@user)

        @build_list = FactoryGirl.create(:build_list_by_group_project)
        @project = @build_list.project
        @owner_group = @build_list.project.owner
        @owner_user =  @owner_group.owner

        @member_group = FactoryGirl.create(:group)
        @member_user = FactoryGirl.create(:user)
        create_actor_relation(@member_group, @member_user, 'reader')
        create_relation(@project, @member_group, 'reader')

        @show_params = { name_with_owner: @project.name_with_owner, id: @build_list.id }
      end

      context 'for all build lists' do
        before do
          @build_list1 = FactoryGirl.create(:build_list)

          @build_list2 = FactoryGirl.create(:build_list)
          @build_list2.project.update_column(:visibility, 'hidden')

          project = FactoryGirl.create(:project_with_commit, visibility: 'hidden', owner: @user)
          @build_list3 = FactoryGirl.create(:build_list_with_attaching_project, project: project)

          @build_list4 = FactoryGirl.create(:build_list)
          @build_list4.project.update_column(:visibility, 'hidden')
          create_relation(@build_list4.project, @user, 'reader')
        end

        it 'should be able to perform index action' do
          get :index
          expect(response).to be_success
        end

        it 'should show only accessible build_lists' do
          get :index, filter: {ownership: 'everything'}, format: :json
          expect(assigns(:build_lists)).to include(@build_list1)
          expect(assigns(:build_lists)).to_not include(@build_list2)
          expect(assigns(:build_lists)).to include(@build_list3)
          expect(assigns(:build_lists)).to include(@build_list4)
        end
      end

      context 'for open project' do
        it_should_behave_like 'show build list'
        it_should_behave_like 'not create build list'

        context 'if user is group owner' do
          before {set_session_for(@owner_user)}
          it_should_behave_like 'show build list'
          it_should_behave_like 'create build list'
        end

        context 'if user is group read member' do
          before {set_session_for(@member_user)}
          it_should_behave_like 'show build list'
          it_should_behave_like 'not create build list'
        end
      end

      context 'for hidden project' do
        before do
          @project.visibility = 'hidden'
          @project.save
        end

        it_should_behave_like 'not show build list'
        it_should_behave_like 'not create build list'

        context 'if user is group owner' do
          before {set_session_for(@owner_user)}
          it_should_behave_like 'show build list'
          it_should_behave_like 'create build list'
        end

        context 'if user is group read member' do
          before {set_session_for(@member_user)}
          it_should_behave_like 'show build list'
          it_should_behave_like 'not create build list'
        end
      end

    end
  end

  context 'filter' do

    before do
      set_session_for FactoryGirl.create(:admin)

      @build_list1 = FactoryGirl.create(:build_list)
      @build_list2 = FactoryGirl.create(:build_list)
      @build_list3 = FactoryGirl.create(:build_list)
      @build_list4 = FactoryGirl.create(:build_list, updated_at: (Time.now - 1.day),
                             project: @build_list3.project, save_to_platform: @build_list3.save_to_platform,
                             arch: @build_list3.arch)
    end

    it 'should filter by id' do
      get :index, filter: {id: @build_list1.id, project_name: 'fdsfdf', any_other_field: 'do not matter'}, format: :json
      expect(assigns[:build_lists]).to include(@build_list1)
      expect(assigns[:build_lists]).to_not include(@build_list2)
      expect(assigns[:build_lists]).to_not include(@build_list3)
    end

    it 'should filter by project_name' do
      # Project.where(id: build_list2.project.id).update_all(name: 'project_name')
      get :index, filter: {project_name: @build_list2.project.name, ownership: 'everything'}, format: :json
      expect(assigns[:build_lists]).to_not include(@build_list1)
      expect(assigns[:build_lists]).to include(@build_list2)
      expect(assigns[:build_lists]).to_not include(@build_list3)
    end

    it 'should filter by project_name and update_date' do
      get :index, filter: {project_name: @build_list3.project.name, ownership: 'everything',
                            "updated_at_start" => @build_list3.updated_at.strftime('%d/%m/%Y')}, format: :json
      expect(assigns[:build_lists]).to_not include(@build_list1)
      expect(assigns[:build_lists]).to_not include(@build_list2)
      expect(assigns[:build_lists]).to include(@build_list3)
      expect(assigns[:build_lists]).to_not include(@build_list4)
    end
  end

  after(:all) {clean_projects_dir}
end
