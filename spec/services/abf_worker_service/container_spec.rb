require 'spec_helper'

describe AbfWorkerService::Container do
  let(:build_list) { FactoryGirl.build(:build_list, id: 123) }

  before do
    stub_symlink_methods
  end

  subject { AbfWorkerService::Container.new(build_list) }

  context '#create!' do

    it 'creates task' do
      expect(Resque).to receive(:push)
      subject.create!
    end

  end

end
