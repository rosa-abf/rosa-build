require 'spec_helper'

describe AbfWorkerService::Container do
  let(:build_list) { FactoryGirl.build(:build_list, id: 123) }

  before do
    stub_symlink_methods
  end

  subject { AbfWorkerService::Container.new(build_list) }

  context '#create!' do

    it 'creates task' do
      expect(build_list).to_not receive(:fail_publish_container)
      expect(Resque).to receive(:push)
      subject.create!
    end

    it 'fails when no packages on FS' do
      expect(subject).to receive(:filter_build_lists_without_packages).and_return([])
      expect(build_list).to receive(:fail_publish_container)
      expect(Resque).to_not receive(:push)
      subject.create!
    end

  end

end
