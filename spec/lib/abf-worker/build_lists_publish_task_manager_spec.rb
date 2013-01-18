require 'spec_helper'

describe AbfWorker::BuildListsPublishTaskManager do
  before(:all) do
    init_test_root
  end

  subject { AbfWorker::BuildListsPublishTaskManager }

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



  after(:all) do
    FileUtils.rm_rf(APP_CONFIG['root_path'])
  end
end
