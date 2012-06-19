# -*- encoding : utf-8 -*-
require 'spec_helper'

describe Projects::BuildListsController do

  shared_examples_for 'show build list' do
    it 'should be able to perform show action' do
      get :show, @show_params
      response.should be_success
    end

    it 'should be able to perform index action in project scope' do
      get :index, :owner_name => @project.owner.uname, :project_name => @project.name
      response.should be_success
    end
  end

  shared_examples_for 'not show build list' do
    it 'should not be able to perform show action' do
      get :show, @show_params
      response.should redirect_to(forbidden_url)
    end

    it 'should not be able to perform index action in project scope' do
      get :index, :owner_name => @project.owner.uname, :project_name => @project.name
      response.should redirect_to(forbidden_url)
    end
  end

  shared_examples_for 'create build list' do
    before {test_git_commit(@project)}

    it 'should be able to perform new action' do
      get :new, :owner_name => @project.owner.uname, :project_name => @project.name
      response.should render_template(:new)
    end

    it 'should be able to perform create action' do
      post :create, {:owner_name => @project.owner.uname, :project_name => @project.name}.merge(@create_params)
      response.should redirect_to project_build_lists_path(@project)
    end

    it 'should save correct commit_hash for branch based build' do
      post :create, {:owner_name => @project.owner.uname, :project_name => @project.name}.merge(@create_params).deep_merge(:build_list => {:project_version => "latest_master"})
      @project.build_lists.last.commit_hash.should == @project.git_repository.commits('master').last.id
    end

    it 'should save correct commit_hash for tag based build' do
      system("cd #{@project.git_repository.path} && git tag 4.7.5.3") # TODO REDO through grit
      post :create, {:owner_name => @project.owner.uname, :project_name => @project.name}.merge(@create_params).deep_merge(:build_list => {:project_version => "4.7.5.3"})
      @project.build_lists.last.commit_hash.should == @project.git_repository.commits('4.7.5.3').last.id
    end
  end

  shared_examples_for 'not create build list' do
    it 'should not be able to perform new action' do
      get :new, :owner_name => @project.owner.uname, :project_name => @project.name
      response.should redirect_to(forbidden_url)
    end

    it 'should not be able to perform create action' do
      post :create, {:owner_name => @project.owner.uname, :project_name => @project.name}.merge(@create_params)
      response.should redirect_to(forbidden_url)
    end
  end

  before { stub_symlink_methods }

  context 'crud' do
    before(:each) do
      platform = FactoryGirl.create(:platform_with_repos)
      @create_params = {
        :build_list => { 
          :project_version => 'latest_master',
          :save_to_platform_id => platform.id,
          :update_type => 'security',
          :include_repos => [platform.repositories.first.id]
        },
        :arches => [FactoryGirl.create(:arch).id],
        :build_for_platforms => [platform.id]
      }
      any_instance_of(Project, :versions => ['v1.0', 'v2.0'])
    end

    context 'for guest' do
      if APP_CONFIG['anonymous_access']
        it 'should be able to perform index action' do
          get :index
          response.should be_success
        end
      else
        it 'should not be able to perform index action' do
          get :index
          response.should redirect_to(new_user_session_path)
        end
      end
    end

    context 'for user' do
      before(:each) do
        @build_list = FactoryGirl.create(:build_list_core)
        @project = @build_list.project
        @owner_user = @project.owner
        @member_user = FactoryGirl.create(:user)
        rel = @project.relations.build(:role => 'reader')
        rel.actor = @member_user
        rel.save
        @user = FactoryGirl.create(:user)
        set_session_for(@user)
        @show_params = {:owner_name => @project.owner.uname, :project_name => @project.name, :id => @build_list.id}
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
          get :index
          response.should be_success
        end

        it 'should show only accessible build_lists' do
          get :index, :filter => {:ownership => 'index'}
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
          @project.save
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
        @owner_group.actors.create :role => 'reader', :actor_id => @owner_user.id, :actor_type => 'User'
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
        @show_params = {:owner_name => @project.owner.uname, :project_name => @project.name, :id => @build_list.id}
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
          get :index
          response.should be_success
        end

        it 'should show only accessible build_lists' do
          get :index, :filter => {:ownership => 'index'}
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
          @project.visibility = 'hidden'
          @project.save
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

    context 'for admin' do
      before(:each) { set_session_for FactoryGirl.create(:admin) }

      it "should be able to perform index action without exception" do
        any_instance_of(XMLRPC::Client) do |xml_rpc|
          stub(xml_rpc).call do |args|
            raise Timeout::Error
          end
        end
        get :index
        assigns[:build_server_status].should == {}
        response.should be_success
      end    
    end
  end

  context 'filter' do
    
    before(:each) do 
      set_session_for FactoryGirl.create(:admin)

      @build_list1 = FactoryGirl.create(:build_list_core)
      @build_list2 = FactoryGirl.create(:build_list_core)
      @build_list3 = FactoryGirl.create(:build_list_core)
      @build_list4 = FactoryGirl.create(:build_list_core, :created_at => (Time.now - 1.day),
                             :project => @build_list3.project, :save_to_platform => @build_list3.save_to_platform,
                             :arch => @build_list3.arch)
    end

    it 'should filter by bs_id' do
      get :index, :filter => {:bs_id => @build_list1.bs_id, :project_name => 'fdsfdf', :any_other_field => 'do not matter'}
      assigns[:build_lists].should include(@build_list1)
      assigns[:build_lists].should_not include(@build_list2)
      assigns[:build_lists].should_not include(@build_list3)
    end

    it 'should filter by project_name' do
      # Project.where(:id => build_list2.project.id).update_all(:name => 'project_name')
      get :index, :filter => {:project_name => @build_list2.project.name, :ownership => 'index'}
      assigns[:build_lists].should_not include(@build_list1)
      assigns[:build_lists].should include(@build_list2)
      assigns[:build_lists].should_not include(@build_list3)
    end

    it 'should filter by project_name and start_date' do
      get :index, :filter => {:project_name => @build_list3.project.name, :ownership => 'index',
                            "created_at_start(1i)" => @build_list3.created_at.year.to_s,
                            "created_at_start(2i)" => @build_list3.created_at.month.to_s,
                            "created_at_start(3i)" => @build_list3.created_at.day.to_s}
      assigns[:build_lists].should_not include(@build_list1)
      assigns[:build_lists].should_not include(@build_list2)
      assigns[:build_lists].should include(@build_list3)
      assigns[:build_lists].should_not include(@build_list4)
    end
  end

  context 'callbacks' do
    let(:build_list) { FactoryGirl.create(:build_list_core) }
    let(:build_list_package) { FactoryGirl.create(:build_list_package, :build_list_id => build_list.id, :platform_id => build_list.project.repositories.first.platform_id, :project_id => build_list.project_id, :version => "4.7.5.3", :release => 1) }

    before(:each) do
      mock(controller).authenticate_build_service! {true}
    end

    describe 'publish_build' do
      before {
        test_git_commit(build_list.project)
        build_list.update_attribute :commit_hash, build_list.project.git_repository.commits('master').last.id
        build_list.update_attribute(:status, BuildList::BUILD_PUBLISH)
        build_list_package
      }

      def do_get(status)
        get :publish_build, :id => build_list.bs_id, :status => status, :version => '4.7.5.3', :release => '1'
        build_list.reload
      end

      it(:passes) {
        build_list.update_attribute(:status, BuildServer::BUILD_STARTED)
        do_get(BuildServer::SUCCESS)
        response.should be_ok
      }
      # TODO: Remove pending after set_version_and_tag unstub:
      it 'should create correct git tag for correct commit' do
        do_get(BuildServer::SUCCESS)
        build_list.project.git_repository.tags.last.name.should == build_list.package_version
        build_list.project.git_repository.commits(build_list.package_version).last.id.should == build_list.commit_hash
      end
      it(:passes) { lambda{ do_get(BuildServer::SUCCESS) }.should change(build_list, :status).to(BuildList::BUILD_PUBLISHED) }
      it(:passes) { lambda{ do_get(BuildServer::SUCCESS) }.should change(build_list, :package_version).to("#{ build_list_package.platform.name }-4.7.5.3-1") }
      it { lambda{ do_get(BuildServer::ERROR) }.should change(build_list, :status).to(BuildList::FAILED_PUBLISH) }
      it { lambda{ do_get(BuildServer::ERROR) }.should_not change(build_list, :package_version) }
      it { lambda{ do_get(BuildServer::ERROR) }.should change(build_list, :updated_at) }
    end

    describe 'status_build' do
      before do
        @item = build_list.items.create(:name => build_list.project.name, :version => build_list.project_version, :level => 0)
        repo = build_list.save_to_platform.repositories.first
        repo.projects << build_list.project
        @project2 = FactoryGirl.create(:project)
        repo.projects << @project2
      end

      def do_get
        get :status_build, :id => build_list.bs_id, :package_name => build_list.project.name, :status => BuildServer::SUCCESS, :container_path => '/path/to',
            :pkg_info => ActiveSupport::JSON.encode({'srpm' =>  {'fullname' => 'srpm_filename.srpm',
                                                                 'name' => build_list.project.name,
                                                                 'version' => 'version1',
                                                                 'release' => 'release1'},
                                                      'rpm' => [{'fullname' => 'filename1.rpm',
                                                                 'name' => build_list.project.name,
                                                                 'version' => 'version2',
                                                                 'release' => 'release2'},
                                                                {'fullname' => 'filename2.rpm',
                                                                 'name' => @project2.name,
                                                                 'version' => 'version2',
                                                                 'release' => 'release2'}]})
        build_list.reload
        @item.reload
      end

      it { do_get; response.should be_ok }
      it { lambda{ do_get }.should change(@item, :status) }
      it { lambda{ do_get }.should change(build_list, :container_path) }
      it { lambda{ do_get }.should change(build_list, :updated_at) }
      it('should create packages for build list') { lambda{ do_get }.should change(build_list.packages, :count).to(3) }
      it 'should create correct packages for build list' do
        do_get
        package = build_list.packages.order('created_at ASC').first
        package.fullname.should == 'srpm_filename.srpm'
        package.name.should == build_list.project.name
        package.version.should == 'version1'
        package.release.should == 'release1'
        package.package_type == 'source'
        package.build_list.should == build_list
        package.platform.should == build_list.save_to_platform
        package.project.should == build_list.project
      end
    end

    describe 'pre_build' do
      before do
        build_list.update_attribute :status, BuildList::BUILD_PENDING
      end

      def do_get
        get :pre_build, :id => build_list.bs_id
        build_list.reload
      end

      it { do_get; response.should be_ok }
      it { lambda{ do_get }.should change(build_list, :status).to(BuildServer::BUILD_STARTED) }
      it { lambda{ do_get }.should change(build_list, :updated_at) }
    end

    describe 'post_build' do
      def do_get(status)
        build_list.started_at = Time.now
        build_list.save
        get :post_build, :id => build_list.bs_id, :status => status, :container_path => '/path/to'
        build_list.reload
      end

      it { do_get(BuildServer::SUCCESS); response.should be_ok }
      it { lambda{ do_get(BuildServer::SUCCESS) }.should change(build_list, :container_path) }
      it { lambda{ do_get(BuildServer::SUCCESS) }.should change(build_list, :updated_at) }

      context 'with auto_publish' do
        it(:passes) {
          build_list.update_attribute(:started_at, (Time.now - 1.day))
          build_list.update_attribute(:status, BuildServer::BUILD_STARTED)
          build_list.reload
          lambda{ do_get(BuildServer::SUCCESS) }.should change(build_list, :status).to(BuildList::BUILD_PUBLISH)
        }
        it(:passes) {
          build_list.update_attribute(:started_at, (Time.now - 1.day))
          build_list.update_attribute(:status, BuildServer::BUILD_STARTED)
          lambda{ do_get(BuildServer::BUILD_ERROR) }.should change(build_list, :status).to(BuildServer::BUILD_ERROR)
        }
      end

      context 'without auto_publish' do
        before { build_list.update_attribute(:auto_publish, false) }

        it(:passes) {
          build_list.update_attribute(:started_at, (Time.now - 1.day))
          build_list.update_attribute(:status, BuildServer::BUILD_STARTED)
          lambda{ do_get(BuildServer::SUCCESS) }.should change(build_list, :status).to(BuildServer::SUCCESS)
        }
        it(:passes) {
          build_list.update_attribute(:started_at, (Time.now - 1.day))
          build_list.update_attribute(:status, BuildServer::BUILD_STARTED)
          lambda{ do_get(BuildServer::BUILD_ERROR) }.should change(build_list, :status).to(BuildServer::BUILD_ERROR)
        }
      end
    end

    describe 'circle_build' do
      def do_get
        get :circle_build, :id => build_list.bs_id, :container_path => '/path/to'
        build_list.reload
      end

      it { do_get; response.should be_ok }
      it { lambda{ do_get }.should change(build_list, :is_circle).to(true) }
      it { lambda{ do_get }.should change(build_list, :container_path) }
      it { lambda{ do_get }.should change(build_list, :updated_at) }
    end

    describe 'new_bbdt' do
      before { @items = build_list.items }

      def do_get
        get :new_bbdt, :id => 123, :web_id => build_list.id, :name => build_list.project.name, :is_circular => 1,
            :additional_repos => ActiveSupport::JSON.encode([{:name => 'build_repos'}, {:name => 'main'}]),
            :items => ActiveSupport::JSON.encode(0 => [{:name => build_list.project.name, :version => build_list.project_version}])
        build_list.reload
        @items.reload
      end

      it { do_get; response.should be_ok }
      it { lambda{ do_get }.should change(build_list, :name).to(build_list.project.name) }
      it { lambda{ do_get }.should change(build_list, :additional_repos) }
      it { lambda{ do_get }.should change(@items, :first) }
      it { lambda{ do_get }.should change(build_list, :is_circle).to(true) }
      it { lambda{ do_get }.should change(build_list, :bs_id).to(123) }
      it { lambda{ do_get }.should change(build_list, :updated_at) }
    end
  end
end
