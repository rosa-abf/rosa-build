require 'spec_helper'

describe AbfWorkerService::PlatformMetadata do
  let(:platform) { FactoryGirl.build(:platform, id: 123) }

  before do
    stub_symlink_methods
  end

  subject { AbfWorkerService::PlatformMetadata.new(platform) }

  context '#regenerate!' do

    it 'creates task' do
      expect(platform).to receive(:start_regeneration).and_return(true)
      expect(Resque).to receive(:push)
      subject.regenerate!
    end

  end

end
