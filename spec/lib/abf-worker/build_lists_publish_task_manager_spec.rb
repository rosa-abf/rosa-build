require 'spec_helper'

describe AbfWorker::BuildListsPublishTaskManager do
  before(:all) do
    @publish_workers_count = APP_CONFIG['abf_worker']['publish_workers_count']
    APP_CONFIG['abf_worker']['publish_workers_count'] = 2
  end

  before do
    init_test_root
    stub_symlink_methods
    FactoryGirl.create(:build_list_core, :new_core => true)
  end

  subject { AbfWorker::BuildListsPublishTaskManager }
  let(:build_list)  { FactoryGirl.create(:build_list_core, :new_core => true) }

  describe 'when no items for publishing' do
    before do
      stub_redis
      subject.new.run
    end

    %w(RESIGN_REPOSITORIES 
       PROJECTS_FOR_CLEANUP
       LOCKED_PROJECTS_FOR_CLEANUP
       LOCKED_REPOSITORIES
       LOCKED_REP_AND_PLATFORMS
       LOCKED_BUILD_LISTS).each do |kind|

      it "ensure that no '#{kind.downcase.gsub('_', ' ')}'" do
        @redis_instance.lrange(subject.const_get(kind), 0, -1).should be_empty
      end
    end

    %w(publish_worker_default publish_worker).each do |kind|
      it "ensure that no tasks in '#{kind}' queue" do
        @redis_instance.lrange(kind, 0, -1).should be_empty
      end
    end

  end

  describe 'when one build_list for publishing' do
    before do
      stub_redis
      build_list.update_column(:status, BuildList::BUILD_PUBLISH)
      2.times{ subject.new.run }
    end
    %w(RESIGN_REPOSITORIES 
       PROJECTS_FOR_CLEANUP
       LOCKED_PROJECTS_FOR_CLEANUP
       LOCKED_REPOSITORIES).each do |kind|

      it "ensure that no '#{kind.downcase.gsub('_', ' ')}'" do
        @redis_instance.lrange(subject.const_get(kind), 0, -1).should be_empty
      end
    end

    it "ensure that 'locked rep and platforms' has only one item" do
      queue = @redis_instance.lrange(subject::LOCKED_REP_AND_PLATFORMS, 0, -1)
      queue.should have(1).item
      queue.should include("#{build_list.save_to_repository_id}-#{build_list.build_for_platform_id}")
    end

    it "ensure that 'locked build lists' has only one item" do
      queue = @redis_instance.lrange(subject::LOCKED_BUILD_LISTS, 0, -1)
      queue.should have(1).item
      queue.should include(build_list.id.to_s)
    end

    it "ensure that new task for publishing has been created" do
      @redis_instance.lrange('queue:publish_worker_default', 0, -1).should have(1).item
    end

  end

  describe 'grouping build lists for publishing into same repository' do
    let(:build_list2) { FactoryGirl.create(:build_list_core,
      :new_core => true,
      :save_to_platform => build_list.save_to_platform,
      :save_to_repository => build_list.save_to_repository,
      :build_for_platform => build_list.build_for_platform
    ) }
    before do
      stub_redis
      build_list.update_column(:status, BuildList::BUILD_PUBLISH)
      build_list2.update_column(:status, BuildList::BUILD_PUBLISH)
      2.times{ subject.new.run }
    end

    %w(RESIGN_REPOSITORIES 
       PROJECTS_FOR_CLEANUP
       LOCKED_PROJECTS_FOR_CLEANUP
       LOCKED_REPOSITORIES).each do |kind|

      it "ensure that no '#{kind.downcase.gsub('_', ' ')}'" do
        @redis_instance.lrange(subject.const_get(kind), 0, -1).should be_empty
      end
    end

    it "ensure that 'locked rep and platforms' has only one item" do
      queue = @redis_instance.lrange(subject::LOCKED_REP_AND_PLATFORMS, 0, -1)
      queue.should have(1).item
      queue.should include("#{build_list.save_to_repository_id}-#{build_list.build_for_platform_id}")
    end

    it "ensure that 'locked build lists' has 2 items" do
      queue = @redis_instance.lrange(subject::LOCKED_BUILD_LISTS, 0, -1)
      queue.should have(2).item
      queue.should include(build_list.id.to_s, build_list2.id.to_s)
    end

    it "ensure that new task for publishing has been created" do
      @redis_instance.lrange('queue:publish_worker_default', 0, -1).should have(1).item
    end

  end

  describe 'creates not more than 4 tasks for publishing' do
    before do
      stub_redis
      build_list.update_column(:status, BuildList::BUILD_PUBLISH)
      4.times {
        bl = FactoryGirl.create(:build_list_core, :new_core => true)
        bl.update_column(:status, BuildList::BUILD_PUBLISH)
      }
      2.times{ subject.new.run }
    end

    it "ensure that 'locked rep and platforms' has 4 items" do
      @redis_instance.lrange(subject::LOCKED_REP_AND_PLATFORMS, 0, -1).should have(4).items
    end

    it "ensure that 'locked build lists' has 4 items" do
      @redis_instance.lrange(subject::LOCKED_BUILD_LISTS, 0, -1).should have(4).items
    end

    it "ensure that new tasks for publishing has been created" do
      @redis_instance.lrange('queue:publish_worker_default', 0, -1).should have(4).items
    end

  end

  describe 'creates task for removing project from repository' do
    before do
      stub_redis
      build_list.update_column(:status, BuildList::BUILD_PUBLISHED)
      FactoryGirl.create(:build_list_package, :build_list => build_list)
      ProjectToRepository.where(:project_id => build_list.project_id, :repository_id => build_list.save_to_repository_id).destroy_all
      2.times{ subject.new.run }
    end

    %w(RESIGN_REPOSITORIES 
       PROJECTS_FOR_CLEANUP
       LOCKED_REPOSITORIES
       LOCKED_BUILD_LISTS).each do |kind|

      it "ensure that no '#{kind.downcase.gsub('_', ' ')}'" do
        @redis_instance.lrange(subject.const_get(kind), 0, -1).should be_empty
      end
    end

    it "ensure that 'locked rep and platforms' has only one item" do
      queue = @redis_instance.lrange(subject::LOCKED_REP_AND_PLATFORMS, 0, -1)
      queue.should have(1).item
      queue.should include("#{build_list.save_to_repository_id}-#{build_list.build_for_platform_id}")
    end

    it "ensure that 'locked projects for cleanup' has only one item" do
      queue = @redis_instance.lrange(subject::LOCKED_PROJECTS_FOR_CLEANUP, 0, -1)
      queue.should have(1).item
      queue.should include("#{build_list.project_id}-#{build_list.save_to_repository_id}-#{build_list.build_for_platform_id}")
    end

    it "ensure that new task for publishing has been created" do
      @redis_instance.lrange('queue:publish_worker_default', 0, -1).should have(1).item
    end

  end

  describe 'grouping build lists for publishing and tasks for removing project from repository' do
    let(:build_list2) { FactoryGirl.create(:build_list_core,
      :new_core => true,
      :save_to_platform => build_list.save_to_platform,
      :save_to_repository => build_list.save_to_repository,
      :build_for_platform => build_list.build_for_platform
    ) }
    let(:build_list3) { FactoryGirl.create(:build_list_core,
      :new_core => true,
      :save_to_platform => build_list.save_to_platform,
      :save_to_repository => build_list.save_to_repository,
      :build_for_platform => build_list.build_for_platform
    ) }
    before do
      stub_redis
      build_list.update_column(:status, BuildList::BUILD_PUBLISH)
      build_list2.update_column(:status, BuildList::BUILD_PUBLISHED)
      build_list3.update_column(:status, BuildList::BUILD_PUBLISHED)
      ProjectToRepository.where(:project_id => build_list3.project_id, :repository_id => build_list3.save_to_repository_id).destroy_all
      2.times{ subject.new.run }
    end

    %w(RESIGN_REPOSITORIES 
       PROJECTS_FOR_CLEANUP
       LOCKED_REPOSITORIES).each do |kind|

      it "ensure that no '#{kind.downcase.gsub('_', ' ')}'" do
        @redis_instance.lrange(subject.const_get(kind), 0, -1).should be_empty
      end
    end

    it "ensure that 'locked rep and platforms' has only one item" do
      queue = @redis_instance.lrange(subject::LOCKED_REP_AND_PLATFORMS, 0, -1)
      queue.should have(1).item
      queue.should include("#{build_list.save_to_repository_id}-#{build_list.build_for_platform_id}")
    end

    it "ensure that 'locked projects for cleanup' has only one item" do
      queue = @redis_instance.lrange(subject::LOCKED_PROJECTS_FOR_CLEANUP, 0, -1)
      queue.should have(1).item
      queue.should include("#{build_list3.project_id}-#{build_list3.save_to_repository_id}-#{build_list3.build_for_platform_id}")
    end

    it "ensure that new task for publishing has been created" do
      @redis_instance.lrange('queue:publish_worker_default', 0, -1).should have(1).item
    end

    it "ensure that 'locked build lists' has only one item" do
      queue = @redis_instance.lrange(subject::LOCKED_BUILD_LISTS, 0, -1)
      queue.should have(1).item
      queue.should include(build_list.id.to_s)
    end
  end

  describe 'resign packages in repository' do
    before do
      stub_redis
      build_list.update_column(:status, BuildList::BUILD_PUBLISH)
      FactoryGirl.create(:key_pair, :repository => build_list.save_to_repository)
      2.times{ subject.new.run }
    end

    %w(RESIGN_REPOSITORIES 
       PROJECTS_FOR_CLEANUP
       LOCKED_PROJECTS_FOR_CLEANUP
       LOCKED_REP_AND_PLATFORMS
       LOCKED_BUILD_LISTS).each do |kind|

      it "ensure that no '#{kind.downcase.gsub('_', ' ')}'" do
        @redis_instance.lrange(subject.const_get(kind), 0, -1).should be_empty
      end
    end

    it "ensure that 'locked repositories' has only one item" do
      queue = @redis_instance.lrange(subject::LOCKED_REPOSITORIES, 0, -1)
      queue.should have(1).item
      queue.should include(build_list.save_to_repository_id.to_s)
    end

    it "ensure that new task for resign has been created" do
      @redis_instance.lrange('queue:publish_worker_default', 0, -1).should have(1).item
    end

  end


  after(:all) do
    APP_CONFIG['abf_worker']['publish_workers_count'] = @publish_workers_count
    FileUtils.rm_rf(APP_CONFIG['root_path'])
  end
end
