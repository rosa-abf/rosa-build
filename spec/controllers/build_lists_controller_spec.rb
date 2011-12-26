require 'spec_helper'

describe BuildListsController do

  shared_examples_for 'show build list' do
    it 'should be able to perform show action' do
      get :show, @show_params
      response.should be_success
    end

    it 'should be able to perform index action in project scope' do
      get :index, :project_id => @project.id
      response.should be_success
    end
  end

  shared_examples_for 'not show build list' do
    it 'should not be able to perform show action' do
      get :show, @show_params
      response.should redirect_to(forbidden_url)
    end

    it 'should not be able to perform index action in project scope' do
      get :index, :project_id => @project.id
      response.should redirect_to(forbidden_url)
    end
  end
  
  shared_examples_for 'create build list' do
    it 'should be able to perform new action' do
      get :new, :project_id => @project.id
      response.should render_template(:new)
    end

    it 'should be able to perform create action' do
      post :create, {:project_id => @project.id}.merge(@create_params)
      response.should redirect_to(@project)
    end
  end

  shared_examples_for 'not create build list' do
    it 'should not be able to perform new action' do
      get :new, :project_id => @project.id
      response.should redirect_to(forbidden_url)
    end

    it 'should not be able to perform create action' do
      post :create, {:project_id => @project.id}.merge(@create_params)
      response.should redirect_to(forbidden_url)
    end
  end

  context 'crud' do
    before(:each) do
      stub_rsync_methods

      platform = Factory(:platform_with_repos)
      @create_params = {
        :build_list => { 
          :project_version => 'v1.0',
          :pl_id => platform.id,
          :update_type => 'security',
          :include_repos => [platform.repositories.first.id]
        },
        :arches => [Factory(:arch).id],
        :bpls => [platform.id]
      }
      any_instance_of(Project, :versions => ['v1.0', 'v2.0'])
    end

    context 'for guest' do
      it 'should not be able to perform index action' do
        get :index
        response.should redirect_to(new_user_session_path)
      end
    end

    context 'for user' do
      before(:each) do
        @build_list = Factory(:build_list_core)
        @project = @build_list.project
        @owner_user = @project.owner
        @member_user = Factory(:user)
        rel = @project.relations.build(:role => 'reader')
        rel.object = @member_user
        rel.save
        @user = Factory(:user)
        set_session_for(@user)
        @show_params = {:project_id => @project.id, :id => @build_list.id}
      end
  
      context 'for all build lists' do
        before(:each) do
          @build_list1 = Factory(:build_list_core)
          @build_list2 = Factory(:build_list_core, :project => Factory(:project, :visibility => 'hidden'))
          @build_list3 = Factory(:build_list_core, :project => Factory(:project, :owner => @user, :visibility => 'hidden'))
            b = Factory(:build_list_core, :project => Factory(:project, :visibility => 'hidden'))
            b.project.relations.create :role => 'reader', :object_id => @user.id, :object_type => 'User'
          @build_list4 = b
        end

        it 'should be able to perform index action' do
          get :index
          response.should be_success
        end

        it 'should show only accessible build_lists' do
          get :index
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
        @owner_group = Factory(:group)
        @owner_user = Factory(:user)
        @owner_group.objects.create :role => 'reader', :object_id => @owner_user.id, :object_type => 'User'
        @member_group = Factory(:group)
        @member_user = Factory(:user)
        @member_group.objects.create :role => 'reader', :object_id => @member_user.id, :object_type => 'User'

        @group = Factory(:group)
        @user = Factory(:user)
        @group.objects.create :role => 'reader', :object_id => @user.id, :object_type => 'User'

        @project = Factory(:project, :owner => @owner_group)
        @project.relations.create :role => 'reader', :object_id => @member_group.id, :object_type => 'Group'

        @build_list = Factory(:build_list_core, :project => @project)

        set_session_for(@user)
        @show_params = {:project_id => @project.id, :id => @build_list.id}
      end
  
      context 'for all build lists' do
        before(:each) do
          @build_list1 = Factory(:build_list_core)
          @build_list2 = Factory(:build_list_core, :project => Factory(:project, :visibility => 'hidden'))
          @build_list3 = Factory(:build_list_core, :project => Factory(:project, :owner => @group, :visibility => 'hidden'))
            b = Factory(:build_list_core, :project => Factory(:project, :visibility => 'hidden'))
            b.project.relations.create :role => 'reader', :object_id => @group.id, :object_type => 'Group'
          @build_list4 = b
        end

        it 'should be able to perform index action' do
          get :index
          response.should be_success
        end

        it 'should show only accessible build_lists' do
          get :index
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
      before(:each) { set_session_for Factory(:admin) }

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
      stub_rsync_methods
      set_session_for Factory(:admin)

      @build_list1 = Factory(:build_list_core)
      @build_list2 = Factory(:build_list_core)
      @build_list3 = Factory(:build_list_core)
      @build_list4 = Factory(:build_list_core, :created_at => (Time.now - 1.day),
                             :project => @build_list3.project, :pl => @build_list3.pl,
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
      get :index, :filter => {:project_name => @build_list2.project.name}
      assigns[:build_lists].should_not include(@build_list1)
      assigns[:build_lists].should include(@build_list2)
      assigns[:build_lists].should_not include(@build_list3)
    end

    it 'should filter by project_name and start_date' do
      get :index, :filter => {:project_name => @build_list3.project.name, 
                            "created_at_start(1i)" => @build_list3.created_at.year.to_s,
                            "created_at_start(2i)" => @build_list3.created_at.month.to_s,
                            "created_at_start(3i)" => @build_list3.created_at.day.to_s}
      assigns[:build_lists].should_not include(@build_list1)
      assigns[:build_lists].should_not include(@build_list2)
      assigns[:build_lists].should include(@build_list3)
      assigns[:build_lists].should_not include(@build_list4)
#      response.should be_success
    end
  end

  context 'callbacks' do
  end
end
