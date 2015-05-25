require 'spec_helper'

describe Group do
  let(:group) { FactoryGirl.build(:group) }

  before { stub_symlink_methods }

  it { should_not allow_value("How do you do...\nmy_group").for(:uname) }

  it 'is valid given valid attributes' do
    expect(group).to be_valid
  end

end
