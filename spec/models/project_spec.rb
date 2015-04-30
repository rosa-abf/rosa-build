require 'spec_helper'

describe Project do
  before { stub_symlink_methods }

  context '#fork' do
    let(:root_project)        { FactoryGirl.create(:project_with_commit) }
    let(:child_project)       { root_project.fork(FactoryGirl.create(:user)) }
    let(:child_child_project) { child_project.fork(FactoryGirl.create(:user)) }
    let(:alias_project)       { root_project.fork(FactoryGirl.create(:user), is_alias: true) }
    let(:alias_alias_project) { alias_project.fork(FactoryGirl.create(:user), is_alias: true) }

    context 'creation' do

      it { root_project }

      it 'creates child project' do
        expect(child_project).to be_valid
        expect(child_project.parent).to eq(root_project)
        expect(child_project.alias_from).to be_nil
        expect{ Grit::Repo.new(child_project.path) }.to_not raise_exception
      end

      it 'creates child-child project' do
        expect(child_child_project).to be_valid
        expect(child_child_project.parent).to eq(child_project)
        expect(child_child_project.alias_from).to be_nil
        expect{ Grit::Repo.new(child_child_project.path) }.to_not raise_exception
      end

      it 'creates alias project' do
        expect(alias_project).to be_valid
        expect(alias_project.parent).to eq(root_project)
        expect(alias_project.alias_from).to eq(root_project)
        expect{ Grit::Repo.new(alias_project.path) }.to_not raise_exception
      end

      it 'creates alias-alias project' do
        expect(alias_alias_project).to be_valid
        expect(alias_alias_project.parent).to eq(alias_project)
        expect(alias_alias_project.alias_from).to eq(root_project)
        expect{ Grit::Repo.new(alias_alias_project.path) }.to_not raise_exception
      end

      it 'ensures that aliased projects have a same default branch' do
        new_default_branch = 'conflicts'
        alias_project.update_attributes default_branch: new_default_branch
        expect(alias_project.parent.default_branch).to eq(new_default_branch)
      end

      it 'ensures that forked project allowed to have another default branch' do
        fill_project root_project
        fill_project child_project
        new_default_branch = 'conflicts'
        child_project.update_attributes default_branch: new_default_branch
        expect(child_project.parent.default_branch).to_not eq(new_default_branch)
      end
    end

    context 'for destroy' do

      it 'root project' do
        child_child_project # init chain of projects
        expect do
          root_project.destroy
        end.to change(Project, :count).by(-1)
      end

      it 'middle child node' do
        child_child_project # init chain of projects
        expect do
          child_project.destroy
        end.to change(Project, :count).by(-1)
      end

      it 'alias nodes' do
        alias_alias_project # init chain of projects
        expect do
          alias_project.destroy
        end.to change(Project, :count).by(-1)
        expect{ Grit::Repo.new(root_project.path)        }.to_not raise_exception
        expect{ Grit::Repo.new(alias_alias_project.path) }.to_not raise_exception
        expect{ Grit::Repo.new(alias_project.path)       }.to     raise_exception

        expect do
          alias_alias_project.destroy
        end.to change(Project, :count).by(-1)
        expect{ Grit::Repo.new(root_project.path)        }.to_not raise_exception
        expect{ Grit::Repo.new(alias_alias_project.path) }.to     raise_exception

        expect do
          root_project.destroy
        end.to change(Project, :count).by(-1)
        expect{ Grit::Repo.new(root_project.path)              }.to raise_exception
        expect{ Grit::Repo.new(root_project.send(:alias_path)) }.to raise_exception
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
  end

  context 'attach personal repository' do
    let(:user) { FactoryGirl.create(:user) }
    it "ensures that personal repository has been attached when project had been created as package" do
      project = FactoryGirl.create(:project, owner: user, is_package: true)
      project.repositories.should == [user.personal_repository]
    end

    it "ensures that personal repository has not been attached when project had been created as not package" do
      project = FactoryGirl.create(:project, owner: user, is_package: false)
      expect(project.repositories.count).to eq 0
    end

    it "ensures that personal repository has been attached when project had been updated as package" do
      project = FactoryGirl.create(:project, owner: user, is_package: false)
      project.update_attribute(:is_package, true)
      project.repositories.should == [user.personal_repository]
    end

    it "ensures that personal repository has been removed from project when project had been updated as not package" do
      project = FactoryGirl.create(:project, owner: user, is_package: true)
      project.update_attribute(:is_package, false)
      expect(project.repositories.count).to eq 0
    end
  end

  context 'truncates project name before validation' do
    let!(:project) { FactoryGirl.build(:project, name: '  test_name  ') }

    it 'ensures that validation passed' do
      project.valid?.should be_truthy
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
    Dir.exists?(project.path).should be_truthy
  end

  context 'manage branches' do
    let!(:project) { FactoryGirl.create(:project_with_commit) }
    let(:branch) { project.repo.branches.detect{|b| b.name == 'conflicts'} }
    let(:master) { project.repo.branches.detect{|b| b.name == 'master'} }
    let(:user) { FactoryGirl.create(:user) }

    context '#delete_branch' do
      it 'ensures that returns true on success' do
        project.delete_branch(branch, user).should be_truthy
      end

      it 'ensures that branch has been deleted' do
        lambda { project.delete_branch(branch, user) }.should change{ project.repo.branches.count }.by(-1)
      end

      it 'ensures that returns false on delete master' do
        project.delete_branch(master, user).should be_falsy
      end

      it 'ensures that master has not been deleted' do
        lambda { project.delete_branch(master, user) }.should change{ project.repo.branches.count }.by(0)
      end

      it 'ensures that returns false on delete wrong branch' do
        project.delete_branch(branch, user)
        project.delete_branch(branch, user).should be_falsy
      end
    end

    context '#create_branch' do
      before do
        project.delete_branch(branch, user)
      end

      it 'ensures that returns true on success' do
        project.create_branch(branch.name, branch.commit.id, user).should be_truthy
      end

      it 'ensures that branch has been created' do
        lambda { project.create_branch(branch.name, branch.commit.id, user) }.should change{ project.repo.branches.count }.by(1)
      end

      it 'ensures that returns false on create wrong branch' do
        project.create_branch(branch.name, GitHook::ZERO, user).should be_falsy
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
      expect(repository.projects.count).to eq 2
      expect(owner.projects.count).to eq 2
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

    it { expect(ProjectToRepository.autostart_enabled.count).to eq 1 }
    it { expect(repository.platform.platform_arch_settings.count).to eq 2 }

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
    it { expect(ProjectToRepository.autostart_enabled.count).to eq 5 }
    it { expect(main_repository.platform.platform_arch_settings.count).to eq 2 }

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

  context '#resolve_default_branch' do
    let(:project)       { FactoryGirl.build(:project) }
    let(:group_project) { FactoryGirl.build(:group_project) }

    it 'returns project default branch if owner is User' do
      expect(project.resolve_default_branch).to eq 'master'
    end

    it 'returns project default branch if Group has no default branch' do
      expect(group_project.resolve_default_branch).to eq 'master'
    end

    it 'returns project default branch if Group default branch does not exist in project' do
      group_project.owner.default_branch = 'rosa'
      expect(group_project.repo).to receive(:branches).and_return([])
      expect(group_project.resolve_default_branch).to eq 'master'
    end

    context 'default branch of Group exists in project' do
      before do
        group_project.owner.default_branch = 'rosa'
        expect(group_project.repo).to receive(:branches).and_return([double(:branch, name: 'rosa')])
      end

      it 'returns Group default branch' do
        expect(group_project.resolve_default_branch).to eq 'rosa'
      end

      it 'returns project default branch if it not equal to master' do
        group_project.default_branch = 'cooker'
        expect(group_project.resolve_default_branch).to eq 'cooker'
      end
    end

  end
end
