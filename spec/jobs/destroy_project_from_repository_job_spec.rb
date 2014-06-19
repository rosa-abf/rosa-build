require 'spec_helper'

describe DestroyProjectFromRepositoryJob do
  let(:project)     { FactoryGirl.build(:project, id: 123) }
  let(:repository)  { FactoryGirl.build(:repository, id: 234) }

  before do
    stub_symlink_methods
    allow(Project).to     receive(:find).with(123).and_return(project)
    allow(Repository).to  receive(:find).with(234).and_return(repository)
  end

  subject { DestroyProjectFromRepositoryJob }

  it 'ensures that not raises error' do
    expect do
      subject.perform 123, 234
    end.to_not raise_exception
  end

end
