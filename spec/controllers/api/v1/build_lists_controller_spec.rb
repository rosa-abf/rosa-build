# -*- encoding : utf-8 -*-
require 'spec_helper'

shared_examples_for 'show build list' do
  it 'should be able to perform show action' do
    get :show, @show_params
    response.should render_template("api/v1/build_lists/show")
  end

  it 'should be able to perform index action in project scope' do
    get :index, :format => :json
    response.should render_template("api/v1/build_lists/index")
  end
end

shared_examples_for 'not show build list' do
  it 'should not be able to perform show action' do
    get :show, @show_params
    response.body.should == {"message" => "Access violation to this page!"}.to_json
  end

  it 'should not be able to perform index action in project scope' do
    get :index, :format => :json
    response.body.should == {"message" => "Access violation to this page!"}.to_json
  end
end

shared_examples_for 'create build list' do
  before {test_git_commit(@project)}

  it 'should create one more build list' do
    lambda { post :create, @create_params.deep_merge(:build_list => {:project_version => "latest_master"}) }.should change{ BuildList.count }.by(1)
  end

  it 'should save correct commit_hash for branch based build' do
    post :create, @create_params.deep_merge(:build_list => {:project_version => "latest_master"})
    @project.build_lists.last.commit_hash.should == @project.repo.commits('master').last.id
  end

  it 'should save correct commit_hash for tag based build' do
    system("cd #{@project.repo.path} && git tag 4.7.5.3") # TODO REDO through grit
    post :create, @create_params.deep_merge(:build_list => {:project_version => "4.7.5.3"})
    @project.build_lists.last.commit_hash.should == @project.repo.commits('4.7.5.3').last.id
  end
end

shared_examples_for 'not create build list' do
  it 'should not be able to perform create action' do
    post :create, @create_params
    response.body.should == {"message" => "Access violation to this page!"}.to_json
  end

  it 'should not create one more build list' do
    lambda { post :create, @create_params }.should change{ BuildList.count }.by(0)
  end
end

describe Api::V1::BuildListsController do
  before(:each) do
    stub_symlink_methods
    # TODO: What a fuck?! Arches doesn't clear after tests finish O_o
    Arch.destroy_all
    @build_list = FactoryGirl.create(:build_list_core)
    @project = @build_list.project
  end

  context 'crud' do
    before(:each) do
      platform = FactoryGirl.create(:platform_with_repos)
      @create_params = {
        :build_list => {
          :project_id => @project.id,
          :save_to_platform_id => platform.id,
          :update_type => 'security',
          :include_repos => [platform.repositories.first.id]
        },
        :arches => [FactoryGirl.create(:arch).id],
        :build_for_platforms => [platform.id],
        :project_id => @project.id,
        :format => :json
      }
      any_instance_of(Project, :versions => ['v1.0', 'v2.0'])
    end

    context 'for guest' do
      if APP_CONFIG['anonymous_access']
        it 'should be able to perform index action' do
          get :index, :format => :json
          response.should be_success
        end
      else
        it 'should not be able to perform index action' do
          get :index, :format => :json
          response.status.should == 401
        end
      end
    end

    context 'for user' do
      before(:each) do
        @owner_user = @project.owner
        @member_user = FactoryGirl.create(:user)
        rel = @project.relations.build(:role => 'reader')
        rel.actor = @member_user
        rel.save
        @user = FactoryGirl.create(:user)
        set_session_for(@user)
        @show_params = {:id => @build_list.id, :format => :json}
      end

      context "do cancel" do
        def do_cancel
          get :cancel, :id => @build_list, :format => :json
        end

        context 'if user is project owner' do
          before(:each) {set_session_for(@owner_user)}

          context "if it has :build_pending status" do
            it "should return correct json message" do
              @build_list.update_attribute(:status, BuildList::BUILD_PENDING)
              do_cancel
              response.body.should == {:is_canceled => true, :url => api_v1_build_list_path(@build_list, :format => :json), :message => I18n.t('layout.build_lists.cancel_success')}.to_json
            end

            it "should cancel build list" do
              @build_list.update_attribute(:status, BuildList::BUILD_PENDING)
              do_cancel
              @build_list.reload.status.should == BuildList::BUILD_CANCELED
            end
          end

          context "if it has another status" do
            it "should return correct json error message" do
              @build_list.update_attribute(:status, BuildServer::PROJECT_NOT_FOUND)
              do_cancel
              # TODO: May be it sends access violation msg!!!
              #       If we not remove can_cancel? from ability.rb it will be only access violation!
              response.body.should == {:is_canceled => false, :url => api_v1_build_list_path(@build_list, :format => :json), :message => I18n.t('layout.build_lists.cancel_fail')}.to_json
            end

            it "should not cancel build list" do
              @build_list.update_attribute(:status, BuildServer::PROJECT_NOT_FOUND)
              do_cancel
              @build_list.reload.status.should == BuildServer::PROJECT_NOT_FOUND
            end
          end
        end

        context 'if user is not project owner' do
          before(:each) do
            @build_list.update_attribute(:status, BuildList::BUILD_PENDING)
            do_cancel
          end

          it "should return access violation message" do
            response.body.should == {"message" => "Access violation to this page!"}.to_json
          end

          it "should not cancel build list" do
            @build_list.reload.status.should == BuildList::BUILD_PENDING
          end
        end
      end

      context "do publish" do
        def do_publish
          get :publish, :id => @build_list, :format => :json
        end

        context 'if user is project owner' do
          before(:each) do
            set_session_for(@owner_user)
            @build_list.update_attribute(:status, BuildList::FAILED_PUBLISH)
            do_publish
          end

          context "if it has :failed_publish status" do
            it "should return correct json message" do
              response.body.should == {:is_published => true, :url => api_v1_build_list_path(@build_list, :format => :json), :message => I18n.t('layout.build_lists.publish_success')}.to_json
            end

            it "should cancel build list" do
              @build_list.reload.status.should == BuildList::BUILD_PUBLISH
            end
          end

          context "if it has another status" do
            before(:each) do
              @build_list.update_attribute(:status, BuildServer::PROJECT_NOT_FOUND)
              do_publish
            end

            it "should return correct json error message" do
              # TODO: May be it sends access violation msg!!!
              #       If we not remove can_cancel? from ability.rb it will be only access violation!
              response.body.should == {:is_published => false, :url => api_v1_build_list_path(@build_list, :format => :json), :message => I18n.t('layout.build_lists.publish_fail')}.to_json
            end

            it "should not cancel build list" do
              @build_list.reload.status.should == BuildServer::PROJECT_NOT_FOUND
            end
          end
        end

        context 'if user is not project owner' do
          before(:each) do
            @build_list.update_attribute(:status, BuildList::FAILED_PUBLISH)
            do_publish
          end

          it "should return access violation message" do
            response.body.should == {"message" => "Access violation to this page!"}.to_json
          end

          it "should not cancel build list" do
            @build_list.reload.status.should == BuildList::FAILED_PUBLISH
          end
        end
      end

      context "do reject_publish" do
        before(:each) do
          any_instance_of(BuildList, :current_duration => 100)
        end

        def do_reject_publish
          get :reject_publish, :id => @build_list, :format => :json
        end

        context 'if user is project owner' do
          before(:each) do
            set_session_for(@owner_user)
            @build_list.update_attribute(:status, BuildServer::SUCCESS)
            @build_list.save_to_platform.update_attribute(:released, true)
            do_reject_publish
          end

          context "if it has :failed_publish status" do
            it "should return correct json message" do
              response.body.should == {:is_reject_published => true, :url => api_v1_build_list_path(@build_list, :format => :json), :message => I18n.t('layout.build_lists.reject_publish_success')}.to_json
            end

            it "should cancel build list" do
              @build_list.reload.status.should == BuildList::BUILD_PUBLISH
            end
          end

          context "if it has another status" do
            before(:each) do
              @build_list.update_attribute(:status, BuildServer::PROJECT_NOT_FOUND)
              do_reject_publish
            end

            it "should return correct json error message" do
              # TODO: May be it sends access violation msg!!!
              #       If we not remove can_cancel? from ability.rb it will be only access violation!
              response.body.should == {:is_reject_published => false, :url => api_v1_build_list_path(@build_list, :format => :json), :message => I18n.t('layout.build_lists.reject_publish_fail')}.to_json
            end

            it "should not cancel build list" do
              @build_list.reload.status.should == BuildServer::PROJECT_NOT_FOUND
            end
          end
        end

        context 'if user is not project owner' do
          before(:each) do
            @build_list.update_attribute(:status, BuildServer::SUCCESS)
            @build_list.save_to_platform.update_attribute(:released, true)
            do_reject_publish
          end

          it "should return access violation message" do
            response.body.should == {"message" => "Access violation to this page!"}.to_json
          end

          it "should not cancel build list" do
            do_reject_publish
            @build_list.reload.status.should == BuildServer::SUCCESS
          end
        end
      end

      context 'for all build lists' do
        before(:each) do
          @build_list1 = FactoryGirl.create(:build_list_core)
          @build_list2 = FactoryGirl.create(:build_list_core, :project => FactoryGirl.create(:project, :visibility => 'hidden'))
          @build_list3 = FactoryGirl.create(:build_list_core, :project => FactoryGirl.create(:project, :owner => @user, :visibility => 'hidden'))
          @build_list4 = FactoryGirl.create(:build_list_core, :project => FactoryGirl.create(:project, :visibility => 'hidden'))
          @build_list4.project.relations.create :role => 'reader', :actor_id => @user.id, :actor_type => 'User'
        end

        it 'should be able to perform index action' do
          get :index, :format => :json
          response.should be_success
        end

        it 'should show only accessible build_lists' do
          get :index, :filter => {:ownership => 'index'}, :format => :json
          assigns(:build_lists).should include(@build_list1)
          assigns(:build_lists).should_not include(@build_list2)
          assigns(:build_lists).should include(@build_list3)
          assigns(:build_lists).should include(@build_list4)
        end
      end

      context 'for open project' do
        it_should_behave_like 'show build list'
        it_should_behave_like 'not create build list'

        context 'if user is project owner' do
          before(:each) {set_session_for(@owner_user)}
          it_should_behave_like 'show build list'
          it_should_behave_like 'create build list'
        end

        context 'if user is project read member' do
          before(:each) {set_session_for(@member_user)}
          it_should_behave_like 'show build list'
          it_should_behave_like 'not create build list'
        end
      end

      context 'for hidden project' do
        before(:each) do
          @project.visibility = 'hidden'
          @project.save!
        end

        it_should_behave_like 'not show build list'
        it_should_behave_like 'not create build list'

        context 'if user is project owner' do
          before(:each) {set_session_for(@owner_user)}
          it_should_behave_like 'show build list'
          it_should_behave_like 'create build list'
        end

        context 'if user is project read member' do
          before(:each) {set_session_for(@member_user)}
          it_should_behave_like 'show build list'
          it_should_behave_like 'not create build list'
        end
      end
    end

    context 'for group' do
      before(:each) do
        @owner_group = FactoryGirl.create(:group)
        @owner_user = FactoryGirl.create(:user)
        @owner_group.actors.create :role => 'admin', :actor_id => @owner_user.id, :actor_type => 'User'
        @member_group = FactoryGirl.create(:group)
        @member_user = FactoryGirl.create(:user)
        @member_group.actors.create :role => 'reader', :actor_id => @member_user.id, :actor_type => 'User'

        @group = FactoryGirl.create(:group)
        @user = FactoryGirl.create(:user)
        @group.actors.create :role => 'reader', :actor_id => @user.id, :actor_type => 'User'

        @project = FactoryGirl.create(:project, :owner => @owner_group)
        @project.relations.create :role => 'reader', :actor_id => @member_group.id, :actor_type => 'Group'

        @build_list = FactoryGirl.create(:build_list_core, :project => @project)

        set_session_for(@user)
        @show_params = {:id => @build_list.id, :format => :json}
      end

      context 'for all build lists' do
        before(:each) do
          @build_list1 = FactoryGirl.create(:build_list_core)
          @build_list2 = FactoryGirl.create(:build_list_core, :project => FactoryGirl.create(:project, :visibility => 'hidden'))
          @build_list3 = FactoryGirl.create(:build_list_core, :project => FactoryGirl.create(:project, :owner => @group, :visibility => 'hidden'))
          @build_list4 = FactoryGirl.create(:build_list_core, :project => FactoryGirl.create(:project, :visibility => 'hidden'))
          @build_list4.project.relations.create :role => 'reader', :actor_id => @group.id, :actor_type => 'Group'
        end

        it 'should be able to perform index action' do
          get :index, :format => :json
          response.should be_success
        end

        it 'should show only accessible build_lists' do
          get :index, :filter => {:ownership => 'index'}, :format => :json
          assigns(:build_lists).should include(@build_list1)
          assigns(:build_lists).should_not include(@build_list2)
          assigns(:build_lists).should include(@build_list3)
          assigns(:build_lists).should include(@build_list4)
        end
      end

      context 'for open project' do
        it_should_behave_like 'show build list'
        it_should_behave_like 'not create build list'

        context 'if user is group owner' do
          before(:each) {set_session_for(@owner_user)}
          it_should_behave_like 'show build list'
          it_should_behave_like 'create build list'
        end

        context 'if user is group read member' do
          before(:each) {set_session_for(@member_user)}
          it_should_behave_like 'show build list'
          it_should_behave_like 'not create build list'
        end
      end

      context 'for hidden project' do
        before(:each) do
          #@project.visibility = 'hidden'
          #@project.save
          @build_list.project.update_attribute(:visibility, 'hidden')
        end

        it_should_behave_like 'not show build list'
        it_should_behave_like 'not create build list'

        context 'if user is group owner' do
          before(:each) {set_session_for(@owner_user)}
          it_should_behave_like 'show build list'
          it_should_behave_like 'create build list'
        end

        context 'if user is group read member' do
          before(:each) {set_session_for(@member_user)}
          it_should_behave_like 'show build list'
          it_should_behave_like 'not create build list'
        end
      end

    end
  end

  context 'filter' do

    before(:each) do
      set_session_for FactoryGirl.create(:admin)

      @build_list1 = FactoryGirl.create(:build_list_core)
      @build_list2 = FactoryGirl.create(:build_list_core)
      @build_list3 = FactoryGirl.create(:build_list_core)
      @build_list4 = FactoryGirl.create(:build_list_core, :updated_at => (Time.now - 1.day),
                             :project => @build_list3.project, :save_to_platform => @build_list3.save_to_platform,
                             :arch => @build_list3.arch)
    end

    it 'should filter by bs_id' do
      get :index, :filter => {:bs_id => @build_list1.bs_id, :project_name => 'fdsfdf', :any_other_field => 'do not matter'}, :format => :json
      assigns[:build_lists].should include(@build_list1)
      assigns[:build_lists].should_not include(@build_list2)
      assigns[:build_lists].should_not include(@build_list3)
    end

    it 'should filter by project_name' do
      get :index, :filter => {:project_name => @build_list2.project.name, :ownership => 'index'}, :format => :json
      assigns[:build_lists].should_not include(@build_list1)
      assigns[:build_lists].should include(@build_list2)
      assigns[:build_lists].should_not include(@build_list3)
    end

    it 'should filter by project_name and start_date' do
      get :index, :filter => {:project_name => @build_list3.project.name, :ownership => 'index',
                            :"updated_at_start(1i)" => @build_list3.updated_at.year.to_s,
                            :"updated_at_start(2i)" => @build_list3.updated_at.month.to_s,
                            :"updated_at_start(3i)" => @build_list3.updated_at.day.to_s}, :format => :json
      assigns[:build_lists].should_not include(@build_list1)
      assigns[:build_lists].should_not include(@build_list2)
      assigns[:build_lists].should include(@build_list3)
      assigns[:build_lists].should_not include(@build_list4)
    end
  end
end
