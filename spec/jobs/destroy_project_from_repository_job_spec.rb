require 'spec_helper'

describe DestroyProjectFromRepositoryJob do
  let(:project)     { FactoryGirl.build(:project, id: 123) }
  let(:repository)  { FactoryGirl.build(:repository, id: 234) }

  before do
    stub_symlink_methods
  end

  subject { DestroyProjectFromRepositoryJob }

  it 'ensures that not raises error' do
    expect do
      subject.perform project, repository
    end.to_not raise_exception
  end

end
