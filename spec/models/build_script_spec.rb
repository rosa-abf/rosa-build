require 'spec_helper'

describe BuildScript do
  before { stub_symlink_methods }

  let(:build_script) { FactoryGirl.build(:build_script) }

  it 'is valid given valid attributes' do
    build_script.should be_valid
  end

  context 'ensures that validations and associations exist' do
    it { should belong_to(:project) }

    it { should validate_presence_of(:project) }
    it { should validate_presence_of(:treeish) }

    context 'uniqueness' do
      before { build_script.save }
      it { should validate_uniqueness_of(:project_id).scoped_to(:treeish) }
    end
  end

end
