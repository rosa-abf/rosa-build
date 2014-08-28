require 'spec_helper'

describe BuildListObserver do

  before { stub_symlink_methods }

  let(:build_list) { FactoryGirl.create(:build_list) }

  it 'updates started_at when build started' do
    expect(build_list.started_at).to be_nil
    build_list.start_build
    expect(build_list.started_at).to_not be_nil
  end

end
