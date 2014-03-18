require 'spec_helper'

describe AbfWorker::BuildListsPublishTaskManager do
  before(:all) do
    @publish_workers_count = APP_CONFIG['abf_worker']['publish_workers_count']
    APP_CONFIG['abf_worker']['publish_workers_count'] = 2
  end

  before do
    stub_symlink_methods
    FactoryGirl.create(:build_list)
  end

  subject { AbfWorker::BuildListsPublishTaskManager }
  let(:build_list)  { FactoryGirl.create(:build_list) }

  context 'when no items for publishing' do
    before { subject.new.run }

    %w(PROJECTS_FOR_CLEANUP
       LOCKED_PROJECTS_FOR_CLEANUP
       LOCKED_BUILD_LISTS).each do |kind|

      it "ensures that no '#{kind.downcase.gsub('_', ' ')}'" do
        @redis_instance.lrange(subject.const_get(kind), 0, -1).should be_empty
      end
    end

    %w(publish_worker_default publish_worker).each do |kind|
      it "ensures that no tasks in '#{kind}' queue" do
        @redis_instance.lrange(kind, 0, -1).should be_empty
      end
    end

  end

  context 'when one build_list for publishing' do
    before do
      build_list.update_column(:status, BuildList::BUILD_PUBLISH)
      2.times{ subject.new.run }
    end
    %w(PROJECTS_FOR_CLEANUP LOCKED_PROJECTS_FOR_CLEANUP).each do |kind|
      it "ensure that no '#{kind.downcase.gsub('_', ' ')}'" do
        @redis_instance.lrange(subject.const_get(kind), 0, -1).should be_empty
      end
    end

    it "ensures that repository_status has status publish" do
      build_list.save_to_repository.repository_statuses.
        find_by(platform_id: build_list.build_for_platform_id).publish?.
        should be_true
    end

    it "ensures that 'locked build lists' has only one item" do
      queue = @redis_instance.lrange(subject::LOCKED_BUILD_LISTS, 0, -1)
      queue.should have(1).item
      queue.should include(build_list.id.to_s)
    end

    it "ensures that new task for publishing has been created" do
      @redis_instance.lrange('queue:publish_worker_default', 0, -1).should have(1).item
    end

  end

  context 'grouping build lists for publishing into same repository' do
    let(:build_list2) { FactoryGirl.create(:build_list,
      new_core: true,
      save_to_platform: build_list.save_to_platform,
      save_to_repository: build_list.save_to_repository,
      build_for_platform: build_list.build_for_platform
    ) }
    before do
      build_list.update_column(:status, BuildList::BUILD_PUBLISH)
      build_list2.update_column(:status, BuildList::BUILD_PUBLISH)
      2.times{ subject.new.run }
    end

    %w(PROJECTS_FOR_CLEANUP LOCKED_PROJECTS_FOR_CLEANUP).each do |kind|
      it "ensures that no '#{kind.downcase.gsub('_', ' ')}'" do
        @redis_instance.lrange(subject.const_get(kind), 0, -1).should be_empty
      end
    end

    it "ensures that only one repository_status has status publish" do
      RepositoryStatus.where(status: RepositoryStatus::PUBLISH).should have(1).item
    end

    it "ensures that 'locked build lists' has 2 items" do
      queue = @redis_instance.lrange(subject::LOCKED_BUILD_LISTS, 0, -1)
      queue.should have(2).item
      queue.should include(build_list.id.to_s, build_list2.id.to_s)
    end

    it "ensures that new task for publishing has been created" do
      @redis_instance.lrange('queue:publish_worker_default', 0, -1).should have(1).item
    end

  end

  context 'creates not more than 4 tasks for publishing' do
    before do
      build_list.update_column(:status, BuildList::BUILD_PUBLISH)
      4.times {
        bl = FactoryGirl.create(:build_list, new_core: true)
        bl.update_column(:status, BuildList::BUILD_PUBLISH)
      }
      2.times{ subject.new.run }
    end

    it "ensures that 4 repository_statuses have status publish" do
      RepositoryStatus.where(status: RepositoryStatus::PUBLISH).should have(4).items
    end

    it "ensures that 'locked build lists' has 4 items" do
      @redis_instance.lrange(subject::LOCKED_BUILD_LISTS, 0, -1).should have(4).items
    end

    it "ensures that new tasks for publishing has been created" do
      @redis_instance.lrange('queue:publish_worker_default', 0, -1).should have(4).items
    end

  end

  context 'creates task for removing project from repository' do
    before do
      build_list.update_column(:status, BuildList::BUILD_PUBLISHED)
      FactoryGirl.create(:build_list_package, build_list: build_list)
      ProjectToRepository.where(project_id: build_list.project_id, repository_id: build_list.save_to_repository_id).destroy_all
      2.times{ subject.new.run }
    end

    %w(LOCKED_BUILD_LISTS).each do |kind|
      it "ensures that no '#{kind.downcase.gsub('_', ' ')}'" do
        @redis_instance.lrange(subject.const_get(kind), 0, -1).should be_empty
      end
    end

    it "ensures that has only 'projects for cleanup' for testing subrepo" do
      queue = @redis_instance.lrange(subject::PROJECTS_FOR_CLEANUP, 0, -1)
      queue.should have(1).item
      queue.should include("testing-#{build_list.project_id}-#{build_list.save_to_repository_id}-#{build_list.build_for_platform_id}")
    end

    it "ensures that only one repository_status has status publish" do
      RepositoryStatus.where(status: RepositoryStatus::PUBLISH).should have(1).item
    end

    it "ensures that 'locked projects for cleanup' has only one item" do
      queue = @redis_instance.lrange(subject::LOCKED_PROJECTS_FOR_CLEANUP, 0, -1)
      queue.should have(1).item
      queue.should include("#{build_list.project_id}-#{build_list.save_to_repository_id}-#{build_list.build_for_platform_id}")
    end

    it "ensures that new task for publishing has been created" do
      @redis_instance.lrange('queue:publish_worker_default', 0, -1).should have(1).item
    end

  end

  context 'grouping build lists for publishing and tasks for removing project from repository' do
    let(:build_list2) { FactoryGirl.create(:build_list,
      new_core: true,
      save_to_platform: build_list.save_to_platform,
      save_to_repository: build_list.save_to_repository,
      build_for_platform: build_list.build_for_platform
    ) }
    let(:build_list3) { FactoryGirl.create(:build_list,
      new_core: true,
      save_to_platform: build_list.save_to_platform,
      save_to_repository: build_list.save_to_repository,
      build_for_platform: build_list.build_for_platform
    ) }
    before do
      build_list.update_column(:status, BuildList::BUILD_PUBLISH)
      build_list2.update_column(:status, BuildList::BUILD_PUBLISHED)
      build_list3.update_column(:status, BuildList::BUILD_PUBLISHED)
      ProjectToRepository.where(project_id: build_list3.project_id, repository_id: build_list3.save_to_repository_id).destroy_all
      2.times{ subject.new.run }
    end

    it "ensures that no 'projects for cleanup' for main repo" do
      queue = @redis_instance.lrange(subject::PROJECTS_FOR_CLEANUP, 0, -1)
      queue.should have(1).item
      queue.should include("testing-#{build_list3.project_id}-#{build_list3.save_to_repository_id}-#{build_list3.build_for_platform_id}")
    end

    it "ensures that only one repository_status has status publish" do
      RepositoryStatus.where(status: RepositoryStatus::PUBLISH).should have(1).item
    end

    it "ensures that 'locked projects for cleanup' has only one item" do
      queue = @redis_instance.lrange(subject::LOCKED_PROJECTS_FOR_CLEANUP, 0, -1)
      queue.should have(1).item
      queue.should include("#{build_list3.project_id}-#{build_list3.save_to_repository_id}-#{build_list3.build_for_platform_id}")
    end

    it "ensures that new task for publishing has been created" do
      @redis_instance.lrange('queue:publish_worker_default', 0, -1).should have(1).item
    end

    it "ensures that 'locked build lists' has only one item" do
      queue = @redis_instance.lrange(subject::LOCKED_BUILD_LISTS, 0, -1)
      queue.should have(1).item
      queue.should include(build_list.id.to_s)
    end
  end

  context 'resign packages in repository' do
    before do
      build_list.update_column(:status, BuildList::BUILD_PUBLISH)
      FactoryGirl.create(:key_pair, repository: build_list.save_to_repository)
      2.times{ subject.new.run }
    end

    %w(PROJECTS_FOR_CLEANUP LOCKED_PROJECTS_FOR_CLEANUP LOCKED_BUILD_LISTS).each do |kind|
      it "ensure that no '#{kind.downcase.gsub('_', ' ')}'" do
        @redis_instance.lrange(subject.const_get(kind), 0, -1).should be_empty
      end
    end

    it "ensures that only one repository_status has status resign" do
      RepositoryStatus.where(status: RepositoryStatus::RESIGN).should have(1).item
    end

    it "ensure that new task for resign has been created" do
      @redis_instance.lrange('queue:publish_worker_default', 0, -1).should have(1).item
    end

  end

  context 'regenerate metadata' do
    context 'for repository of main platform' do
      let(:repository) { FactoryGirl.create(:repository) }
      before do
        repository.regenerate
        subject.new.run
      end

      it "ensures that only one repository_status has status regenerating" do
        RepositoryStatus.where(status: RepositoryStatus::REGENERATING).should have(1).item
      end

      it 'ensures that new task has been created' do
        @redis_instance.lrange('queue:publish_worker_default', 0, -1).should have(1).item
      end
    end

    context 'for repository of personal platform' do
      let(:main_platform) { FactoryGirl.create(:platform) }
      let(:repository) { FactoryGirl.create(:personal_repository) }
      before do
        repository.regenerate main_platform.id
        subject.new.run
      end

      it "ensures that only one repository_status has status regenerating" do
        RepositoryStatus.where(status: RepositoryStatus::REGENERATING).should have(1).item
      end

      it 'ensures that new task has been created' do
        @redis_instance.lrange('queue:publish_worker_default', 0, -1).should have(1).item
      end
    end

  end

  after(:all) do
    APP_CONFIG['abf_worker']['publish_workers_count'] = @publish_workers_count
    FileUtils.rm_rf(APP_CONFIG['root_path'])
  end
end
