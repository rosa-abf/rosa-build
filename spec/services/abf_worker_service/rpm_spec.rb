require 'spec_helper'

describe AbfWorkerService::Rpm do
  let(:build_list) { FactoryGirl.create(:build_list) }

  before(:all) do
    @publish_workers_count = APP_CONFIG['abf_worker']['publish_workers_count']
    APP_CONFIG['abf_worker']['publish_workers_count'] = 2
  end

  after(:all) do
    APP_CONFIG['abf_worker']['publish_workers_count'] = @publish_workers_count
  end

  before do
    stub_symlink_methods
  end

  subject { AbfWorkerService::Rpm }

  context '#publish!' do

    before do
      FactoryGirl.create(:build_list)
    end

    context 'no items for publishing' do

      %w(PROJECTS_FOR_CLEANUP
         LOCKED_PROJECTS_FOR_CLEANUP
         LOCKED_BUILD_LISTS).each do |kind|

        it "ensures that no '#{kind.downcase.gsub('_', ' ')}'" do
          subject.publish!
          @redis_instance.lrange(subject.const_get(kind), 0, -1).should be_empty
        end
      end

      it 'ensures that no tasks' do
        expect(Resque).to_not receive(:push)
        subject.publish!
      end
    end

    context 'when one build_list for publishing' do
      before do
        build_list.update_column(:status, BuildList::BUILD_PUBLISH)
        2.times{ subject.publish! }
      end

      %w(PROJECTS_FOR_CLEANUP LOCKED_PROJECTS_FOR_CLEANUP).each do |kind|
        it "ensure that no '#{kind.downcase.gsub('_', ' ')}'" do
          @redis_instance.lrange(subject.const_get(kind), 0, -1).should be_empty
        end
      end

      it "ensures that repository_status has status publish" do
        build_list.save_to_repository.repository_statuses.
          find_by(platform_id: build_list.build_for_platform_id).publish?.
          should be_truthy
      end

      it "ensures that 'locked build lists' has only one item" do
        queue = @redis_instance.lrange(subject::LOCKED_BUILD_LISTS, 0, -1)
        expect(queue.count).to eq 1
        queue.should include(build_list.id.to_s)
      end

      it "ensures that new task for publishing has been created" do
        expect(@redis_instance.lrange('resque:queue:publish_worker_default', 0, -1).count).to eq 1
      end

    end

    context 'creates not more than 4 tasks for publishing' do
      before do
        build_list.update_column(:status, BuildList::BUILD_PUBLISH)
        4.times do
          bl        = FactoryGirl.build(:build_list)
          bl.status = BuildList::BUILD_PUBLISH
          bl.save!
        end
      end

      it "ensures that 4 repository_statuses have status publish" do
        subject.publish!
        subject.publish!

        expect(RepositoryStatus.where(status: RepositoryStatus::PUBLISH).count).to eq 4
      end

      it "ensures that 'locked build lists' has 4 items" do
        subject.publish!
        subject.publish!

        expect(@redis_instance.lrange(subject::LOCKED_BUILD_LISTS, 0, -1).count).to eq 4
      end

      it "ensures that new tasks for publishing has been created" do
        expect(Resque).to receive(:push).exactly(4).times

        subject.publish!
        subject.publish!
      end
    end

    context 'grouping build lists for publishing into same repository' do
      let(:build_list2) { FactoryGirl.build(:build_list,
        new_core: true,
        save_to_platform: build_list.save_to_platform,
        save_to_repository: build_list.save_to_repository,
        build_for_platform: build_list.build_for_platform
      ) }

      before do
        build_list.update_column(:status, BuildList::BUILD_PUBLISH)
        build_list2.status = BuildList::BUILD_PUBLISH
        build_list2.save!
      end

      %w(PROJECTS_FOR_CLEANUP LOCKED_PROJECTS_FOR_CLEANUP).each do |kind|
        it "ensures that no '#{kind.downcase.gsub('_', ' ')}'" do
          subject.publish!
          subject.publish!
          @redis_instance.lrange(subject.const_get(kind), 0, -1).should be_empty
        end
      end

      it "ensures that only one repository_status has status publish" do
        subject.publish!
        subject.publish!
        expect(RepositoryStatus.where(status: RepositoryStatus::PUBLISH).count).to eq 1
      end

      it "ensures that 'locked build lists' has 2 items" do
        subject.publish!
        subject.publish!
        queue = @redis_instance.lrange(subject::LOCKED_BUILD_LISTS, 0, -1)
        expect(queue.count).to eq 2
        queue.should include(build_list.id.to_s, build_list2.id.to_s)
      end

      it "ensures that new task for publishing has been created" do
        expect(Resque).to receive(:push).once

        subject.publish!
        subject.publish!
      end
    end

    context 'grouping build lists for publishing and tasks for removing project from repository' do
      let(:build_list2) { FactoryGirl.build(:build_list,
        new_core: true,
        save_to_platform: build_list.save_to_platform,
        save_to_repository: build_list.save_to_repository,
        build_for_platform: build_list.build_for_platform
      ) }
      let(:build_list3) { FactoryGirl.build(:build_list,
        new_core: true,
        save_to_platform: build_list.save_to_platform,
        save_to_repository: build_list.save_to_repository,
        build_for_platform: build_list.build_for_platform
      ) }
      before do
        build_list.update_column(:status, BuildList::BUILD_PUBLISH)
        build_list2.status = BuildList::BUILD_PUBLISHED; build_list2.save!
        build_list3.status = BuildList::BUILD_PUBLISHED; build_list3.save!
        ProjectToRepository.where(project_id: build_list3.project_id, repository_id: build_list3.save_to_repository_id).destroy_all
      end

      it "ensures that no 'projects for cleanup' for main repo" do
        subject.publish!
        subject.publish!

        queue = @redis_instance.lrange(subject::PROJECTS_FOR_CLEANUP, 0, -1)
        expect(queue.count).to eq 1
        queue.should include("testing-#{build_list3.project_id}-#{build_list3.save_to_repository_id}-#{build_list3.build_for_platform_id}")
      end

      it "ensures that only one repository_status has status publish" do
        subject.publish!
        subject.publish!

        expect(RepositoryStatus.where(status: RepositoryStatus::PUBLISH).count).to eq 1
      end

      it "ensures that 'locked projects for cleanup' has only one item" do
        subject.publish!
        subject.publish!

        queue = @redis_instance.lrange(subject::LOCKED_PROJECTS_FOR_CLEANUP, 0, -1)
        expect(queue.count).to eq 1
        queue.should include("#{build_list3.project_id}-#{build_list3.save_to_repository_id}-#{build_list3.build_for_platform_id}")
      end

      it "ensures that new task for publishing has been created" do
        expect(Resque).to receive(:push).once

        subject.publish!
        subject.publish!
      end

      it "ensures that 'locked build lists' has only one item" do
        subject.publish!
        subject.publish!
        
        queue = @redis_instance.lrange(subject::LOCKED_BUILD_LISTS, 0, -1)
        expect(queue.count).to eq 1
        queue.should include(build_list.id.to_s)
      end
    end

  end

end
