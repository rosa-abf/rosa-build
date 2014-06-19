require 'spec_helper'

describe AbfWorkerService::Repository do
  let(:repository)  { FactoryGirl.build(:repository, id: 123) }

  before do
    stub_symlink_methods
  end

  subject { AbfWorkerService::Repository.new(repository) }

  context '#destroy_project!' do
    let(:project)     { FactoryGirl.build(:project, id: 234) }

    context 'repository of main platform' do
      let(:key) { "#{project.id}-#{repository.id}-#{repository.platform_id}" }

      it 'adds to PROJECTS_FOR_CLEANUP queue' do
        expect(Redis.current).to receive(:lpush).with(AbfWorkerService::Base::PROJECTS_FOR_CLEANUP, key)
        expect(Redis.current).to receive(:lpush).with(AbfWorkerService::Base::PROJECTS_FOR_CLEANUP, 'testing-' << key)

        subject.destroy_project!(project)
      end

    end

    context 'repository of personal platform' do
      let(:platform1) { FactoryGirl.build(:platform, id: 345) }
      let(:platform2) { FactoryGirl.build(:platform, id: 456) }

      before do
        allow(repository.platform).to receive(:personal?).and_return(true)
        allow(Platform).to receive(:main).and_return([platform1, platform2])
      end

      it 'adds to PROJECTS_FOR_CLEANUP queue' do
        [platform1, platform2].each do |platform|
          key = "#{project.id}-#{repository.id}-#{platform.id}"
          expect(Redis.current).to receive(:lpush).with(AbfWorkerService::Base::PROJECTS_FOR_CLEANUP, key)
          expect(Redis.current).to receive(:lpush).with(AbfWorkerService::Base::PROJECTS_FOR_CLEANUP, 'testing-' << key)
        end

        subject.destroy_project!(project)
      end

    end
  end

  context '#resign!' do
    let(:repository_status) { double(:repository_status, id: 234) }

    it 'creates task' do
      expect(repository_status).to receive(:start_resign).and_return(true)
      expect(Resque).to receive(:push)
      subject.resign!(repository_status)
    end

  end

end
