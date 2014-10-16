require 'spec_helper'

describe BuildLists::CleanBuildrootJob do

  before  { stub_symlink_methods }
  subject { BuildLists::CleanBuildrootJob }

  it 'ensures that not raises error' do
    FactoryGirl.create(:build_list, status: BuildList::BUILD_ERROR)
    expect(FileStoreService::File).to_not receive(:new)
    expect do
      subject.perform
    end.to_not raise_exception
  end

  it 'cleans RPM buildroot' do
    results = [
      { 'sha1' => 'sha1-1', 'file_name' => BuildLists::CleanBuildrootJob::FILENAME },
      { 'sha1' => 'sha1-2', 'file_name' => 'test.log' }
    ]
    FactoryGirl.create(:build_list,
      results:        results,
      save_buildroot: true,
      status:         BuildList::BUILD_ERROR
    )
    bl = FactoryGirl.create(:build_list,
      results:        results,
      save_buildroot: true,
      status:         BuildList::BUILD_ERROR,
      updated_at:     Time.now - 2.hours
    )
    file_store_service = double(:file_store_service, destroy: true)

    expect(FileStoreService::File).to receive(:new).with(sha1: 'sha1-1').and_return(file_store_service)

    subject.perform
    expect(bl.reload.results).to eq [{ 'sha1' => 'sha1-2', 'file_name' => 'test.log' }]
  end

end
