require 'spec_helper'

describe Repository do
  before { stub_symlink_methods }

  context 'ensures that validations and associations exist' do
    before do
      # Need for validate_uniqueness_of check
      FactoryGirl.create(:repository)
    end

    it { should belong_to(:platform) }
    it { should have_many(:project_to_repositories).validate(true) }
    it { should have_many(:projects).through(:project_to_repositories) }

    it { should validate_presence_of(:name) }
    it { should validate_uniqueness_of(:name).case_insensitive.scoped_to(:platform_id) }
    it { should allow_value('basic_repository-name-1234').for(:name) }
    it { should_not allow_value('.!').for(:name) }
    it { should_not allow_value('Main').for(:name) }
    it { should_not allow_value("!!\nbang_bang\n!!").for(:name) }
    it { should validate_presence_of(:description) }

    it { should have_readonly_attribute(:name) }
    it { should have_readonly_attribute(:platform_id) }

    it { should_not allow_mass_assignment_of(:platform) }
    it { should_not allow_mass_assignment_of(:platform_id) }

  end

  context '#sync_lock_file_exists?, #add_sync_lock_file, #remove_sync_lock_file, #add_repo_lock_file, #remove_repo_lock_file' do
    let(:repository) { FactoryGirl.create(:repository) }
    let(:path) { "#{repository.platform.path}/repository/SRPMS/#{repository.name}" }
    before { FileUtils.mkdir_p path }

    it 'ensures that #sync_lock_file_exists? returns false if .sync.lock file does not exist' do
      repository.sync_lock_file_exists?.should be_false
    end

    it 'ensures that #sync_lock_file_exists? returns true if .sync.lock file does exist' do
      FileUtils.touch "#{path}/.sync.lock"
      repository.sync_lock_file_exists?.should be_true
    end

    it 'ensures that #add_sync_lock_file creates .sync.lock file' do
      repository.add_sync_lock_file
      File.exist?("#{path}/.sync.lock").should be_true
    end

    it 'ensures that #remove_sync_lock_file removes .sync.lock file' do
      FileUtils.touch "#{path}/.sync.lock"
      repository.remove_sync_lock_file
      File.exist?("#{path}/.sync.lock").should be_false
    end

    it 'ensures that #add_repo_lock_file creates .repo.lock file' do
      repository.add_repo_lock_file
      File.exist?("#{path}/.repo.lock").should be_true
    end

    it 'ensures that #remove_repo_lock_file removes .repo.lock file' do
      FileUtils.touch "#{path}/.repo.lock"
      repository.remove_repo_lock_file
      File.exist?("#{path}/.repo.lock").should be_false
    end

  end

  context 'when create with same owner that platform' do
    before do
      @platform = FactoryGirl.create(:platform)
      @params = {:name => 'tst_platform', :description => 'test platform'}
    end

    it 'it should increase Repository.count by 1' do
      rep = Repository.create(@params) {|r| r.platform = @platform}
      @platform.repositories.count.should eql(1)
    end
  end

  context 'ensures that folder of repository will be removed after destroy' do
    let(:arch) { FactoryGirl.create(:arch) }
    let(:types) { ['SRPM', arch.name] }

    it "repository of main platform" do
      FactoryGirl.create(:arch)
      r = FactoryGirl.create(:repository)
      paths = types.
        map{ |type| "#{r.platform.path}/repository/#{type}/#{r.name}" }.
        each{ |path| FileUtils.mkdir_p path }
      r.destroy
      paths.each{ |path| Dir.exists?(path).should be_false }
    end

    it "repository of personal platform" do
      FactoryGirl.create(:arch)
      main_platform = FactoryGirl.create(:platform)
      r = FactoryGirl.create(:personal_repository)
      paths = types.
        map{ |type| "#{r.platform.path}/repository/#{main_platform.name}/#{type}/#{r.name}" }.
        each{ |path| FileUtils.mkdir_p path }
      r.destroy
      paths.each{ |path| Dir.exists?(path).should be_false }
    end

  end

  context '#add_projects' do
    it 'user has ability to read of adding project' do
      repository = FactoryGirl.create(:repository)
      project = FactoryGirl.create(:project)
      repository.add_projects("#{project.owner.uname}/#{project.name}", FactoryGirl.create(:user))
      repository.projects.should have(1).item
    end

    it 'user has no ability to read of adding project' do
      repository = FactoryGirl.create(:repository)
      project = FactoryGirl.create(:project, :visibility => 'hidden')
      repository.add_projects("#{project.owner.uname}/#{project.name}", FactoryGirl.create(:user))
      repository.projects.should have(:no).items
    end
  end

  it '#remove_projects' do
    stub_redis
    repository = FactoryGirl.create(:repository)
    project = FactoryGirl.create(:project)
    repository.projects << project
    repository.remove_projects(project.name)
    repository.reload
    repository.projects.should have(:no).items
  end

end
