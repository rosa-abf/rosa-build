require 'spec_helper'

describe AbfWorker::BuildListsPublishTaskManager do
  before(:all) do
    init_test_root
  end

  subject { AbfWorker::BuildListsPublishTaskManager }
  let(:build_list)  { FactoryGirl.create(:build_list_core, :new_core => true) }
  let(:build_list2) { FactoryGirl.create(:build_list_core, :new_core => true) }

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
      build_list.update_column(:status, BuildList::BUILD_PUBLISH)
      stub_redis
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

  end


  after(:all) do
    FileUtils.rm_rf(APP_CONFIG['root_path'])
  end
end
