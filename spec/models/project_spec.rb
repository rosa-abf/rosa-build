require 'spec_helper'

describe Project do
  before { stub_symlink_methods }

  context 'creation' do
    let(:root_project) { FactoryGirl.create(:project) }
    let(:child_project) { root_project.fork(FactoryGirl.create(:user)) }
    let(:child_child_project) { child_project.fork(FactoryGirl.create(:user)) }

    it { root_project }
    it { child_project }
    it { child_child_project }
  end

  context 'for destroy' do
    let!(:root_project) { FactoryGirl.create(:project) }
    let!(:child_project) { root_project.fork(FactoryGirl.create(:user)) }
    let!(:child_child_project) { child_project.fork(FactoryGirl.create(:user)) }

    context 'root project' do
      before { root_project.destroy }

      it "should not be delete child" do
        Project.where(id: child_project).count.should == 1
      end

      it "should not be delete child of the child" do
        Project.where(id: child_child_project).count.should == 1
      end
    end

    pending 'when will be available orphan_strategy: :adopt' do
      context 'middle node' do
        before{ child_project.destroy }

        it "should set root project as a parent for orphan child" do
          Project.find(child_child_project).ancestry == root_project
        end

        it "should not be delete child of the child" do
          Project.where(id: child_child_project).count.should == 1
        end
      end
    end
  end

  context 'attach personal repository' do
    let(:user) { FactoryGirl.create(:user) }
    it "ensures that personal repository has been attached when project had been created as package" do
      project = FactoryGirl.create(:project, owner: user, is_package: true)
      project.repositories.should == [user.personal_repository]
    end

    it "ensures that personal repository has not been attached when project had been created as not package" do
      project = FactoryGirl.create(:project, owner: user, is_package: false)
      project.repositories.should have(:no).items
    end

    it "ensures that personal repository has been attached when project had been updated as package" do
      project = FactoryGirl.create(:project, owner: user, is_package: false)
      project.update_attribute(:is_package, true)
      project.repositories.should == [user.personal_repository]
    end

    it "ensures that personal repository has been removed from project when project had been updated as not package" do
      project = FactoryGirl.create(:project, owner: user, is_package: true)
      project.update_attribute(:is_package, false)
      project.repositories.should have(:no).items
    end
  end

  context 'truncates project name before validation' do
    let!(:project) { FactoryGirl.build(:project, name: '  test_name  ') }

    it 'ensures that validation passed' do
      project.valid?.should be_true
    end

    it 'ensures that name has been truncated' do
      project.valid?
      project.name.should == 'test_name'
    end
  end

  context 'Validate project name' do
    let!(:project) { FactoryGirl.build(:project, name: '  test_name  ') }

    it "'hacked' uname should not pass" do
      lambda {FactoryGirl.create(:project, name: "...\nbeatiful_name\n for project")}.should raise_error(ActiveRecord::RecordInvalid)
    end
  end

  it 'ensures that path to git repository has been changed after rename of project' do
    project = FactoryGirl.create(:project_with_commit)
    project.update_attributes(name: "#{project.name}-new")
    Dir.exists?(project.path).should be_true
  end

  context 'manage branches' do
    let!(:project) { FactoryGirl.create(:project_with_commit) }
    let(:branch) { project.repo.branches.detect{|b| b.name == 'conflicts'} }
    let(:master) { project.repo.branches.detect{|b| b.name == 'master'} }
    let(:user) { FactoryGirl.create(:user) }

    context '#delete_branch' do
      it 'ensures that returns true on success' do
        project.delete_branch(branch, user).should be_true
      end

      it 'ensures that branch has been deleted' do
        lambda { project.delete_branch(branch, user) }.should change{ project.repo.branches.count }.by(-1)
      end

      it 'ensures that returns false on delete master' do
        project.delete_branch(master, user).should be_false
      end

      it 'ensures that master has not been deleted' do
        lambda { project.delete_branch(master, user) }.should change{ project.repo.branches.count }.by(0)
      end

      it 'ensures that returns false on delete wrong branch' do
        project.delete_branch(branch, user)
        project.delete_branch(branch, user).should be_false
      end
    end

    context '#create_branch' do
      before do
        project.delete_branch(branch, user)
      end

      it 'ensures that returns true on success' do
        project.create_branch(branch.name, branch.commit.id, user).should be_true
      end

      it 'ensures that branch has been created' do
        lambda { project.create_branch(branch.name, branch.commit.id, user) }.should change{ project.repo.branches.count }.by(1)
      end

      it 'ensures that returns false on create wrong branch' do
        project.create_branch(branch.name, GitHook::ZERO, user).should be_false
      end
    end

  end

  context '#replace_release_tag' do

    [
      ['Release: %mkrel 4mdk', 'Release: 5mdk'],
      ['Release: 4', 'Release: 5'],
      ['Release: 4.1', 'Release: 4.2'],
      ['Release: 5.4.2', 'Release: 5.4.3'],
      ['Release: 5.4.2mdk', 'Release: 5.4.3mdk'],
      ['Release: %mkrel 5.4.31mdk', 'Release: 5.4.32mdk'],
      ['%define release %mkrel 4mdk', '%define release 5mdk'],
      ['%define release 4', '%define release 5'],
      ['%define release 4.1', '%define release 4.2'],
      ['%define release 5.4.2', '%define release 5.4.3'],
      ['%define release 5.4.31mdk', '%define release 5.4.32mdk']
    ].each do |items|
      it "ensures that replace '#{items[0]}' => '#{items[1]}'" do
        Project.replace_release_tag(items[0]).should == items[1]
      end
    end
  end

  context '#run_mass_import' do
    before  { WebMock.allow_net_connect! }
    after   { WebMock.disable_net_connect! }

    it 'success' do
      owner = FactoryGirl.create(:user)
      repository = FactoryGirl.create(:repository)
      url = 'http://abf-downloads.rosalinux.ru/abf_personal/repository/test-mass-import'
      visibility = 'open'

      
      Project.run_mass_import(url, "abf-worker-service-1-3.src.rpm\nredir-2.2.1-7.res6.src.rpm\n", visibility, owner, repository.id)

      Project.count.should == 2
      repository.projects.should have(2).items
      owner.projects.should have(2).items
    end
  end

  shared_examples_for 'autostart build_lists' do |once_a_12_hours, once_a_day, once_a_week|
    it { lambda { Project.autostart_build_lists_once_a_12_hours }.should change{ BuildList.count }.by(once_a_12_hours) }
    it { lambda { Project.autostart_build_lists_once_a_day }.should change{ BuildList.count }.by(once_a_day) }
    it { lambda { Project.autostart_build_lists_once_a_week }.should change{ BuildList.count }.by(once_a_week) }
  end

  context '#autostart_build_lists_once_a_* for main platform' do
    let(:project) { FactoryGirl.create(:project_with_commit) }
    let(:repository) { FactoryGirl.create(:repository) }
    let(:user) { FactoryGirl.create(:user) }

    before do
      repository.add_member user
      repository.projects << project
      p_to_r = project.project_to_repositories.where(repository_id: repository).first
      p_to_r.enabled = true
      p_to_r.user_id = user.id
      p_to_r.save

      FactoryGirl.create(:platform_arch_setting, platform: repository.platform)
      FactoryGirl.create(:platform_arch_setting, platform: repository.platform, default: false)
    end

    it { ProjectToRepository.autostart_enabled.should have(1).item }
    it { repository.platform.platform_arch_settings.should have(2).item }

    context 'once_a_12_hours' do
      before { project.update_attributes(autostart_status: Autostart::ONCE_A_12_HOURS) }
      it_should_behave_like 'autostart build_lists', 1, 0, 0
    end

    context 'once_a_day' do
      before { project.update_attributes(autostart_status: Autostart::ONCE_A_DAY) }
      it_should_behave_like 'autostart build_lists', 0, 1, 0
    end

    context 'once_a_day' do
      before { project.update_attributes(autostart_status: Autostart::ONCE_A_WEEK) }
      it_should_behave_like 'autostart build_lists', 0, 0, 1
    end

  end

  context '#autostart_build_lists_once_a_* for personal platform' do
    let(:project) { FactoryGirl.create(:project_with_commit) }
    let(:repository) { FactoryGirl.create(:personal_repository) }
    let(:main_repository) { FactoryGirl.create(:repository, name: 'main') }
    let(:user) { FactoryGirl.create(:user) }

    before do
      repositories = [repository, main_repository] # 1

      # Create 1 main platforms with main repositories
      repositories << FactoryGirl.create(:repository, name: 'main') # 2
      # Create platform without main repository
      repositories << FactoryGirl.create(:repository)
      # Hidden platform
      r = FactoryGirl.create(:repository, name: 'main')
      r.platform.update_attributes(visibility: 'hidden')
      repositories << r # 3

      # Without access to hidden platform
      r = FactoryGirl.create(:repository, name: 'main')
      r.platform.update_attributes(visibility: 'hidden')

      repositories.each do |r|
        r.projects << project
        p_to_r = project.project_to_repositories.where(repository_id: r).first
        p_to_r.enabled = true
        p_to_r.user_id = user.id
        p_to_r.save

        FactoryGirl.create(:platform_arch_setting, platform: r.platform) if r.platform.main?
      end

      FactoryGirl.create(:platform_arch_setting, platform: main_repository.platform, default: false)
    end

    # 1(personal) + 2(main) + 1(hidden) + 1(main, without main repository)
    it { ProjectToRepository.autostart_enabled.should have(5).item }
    it { main_repository.platform.platform_arch_settings.should have(2).item }

    # into main platforms: 2 + 1(hidden)
    # into personal platform: 3(main) * 1
    context 'once_a_12_hours' do
      before { project.update_attributes(autostart_status: Autostart::ONCE_A_12_HOURS) }
      it_should_behave_like 'autostart build_lists', 6, 0, 0
    end

    context 'once_a_day' do
      before { project.update_attributes(autostart_status: Autostart::ONCE_A_DAY) }
      it_should_behave_like 'autostart build_lists', 0, 6, 0
    end

    context 'once_a_day' do
      before { project.update_attributes(autostart_status: Autostart::ONCE_A_WEEK) }
      it_should_behave_like 'autostart build_lists', 0, 0, 6
    end
  end
end
