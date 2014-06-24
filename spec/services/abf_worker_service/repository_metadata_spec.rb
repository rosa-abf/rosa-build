require 'spec_helper'

describe AbfWorkerService::RepositoryMetadata do
  let(:repository)        { FactoryGirl.build(:repository, id: 123) }
  let(:platform)          { repository.platform }
  let(:repository_status) { double(:repository_status, id: 234, repository: repository, platform: platform) }

  before do
    stub_symlink_methods
    allow(repository_status).to receive(:start_regeneration).and_return(true)
  end

  subject { AbfWorkerService::RepositoryMetadata.new(repository_status) }

  context '#regenerate!' do

    context 'repository of main platform' do
      it 'creates task' do
        expect(subject).to_not receive(:system)
        expect(Resque).to receive(:push)
        subject.regenerate!
      end
    end

    context 'repository of personal platform' do
      before do
        allow(platform).to receive(:personal?).and_return(true)
      end

      it 'creates task' do
        expect(subject).to receive(:system)
        expect(Resque).to receive(:push)
        subject.regenerate!
      end
    end

  end

end
