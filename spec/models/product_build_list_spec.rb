require 'spec_helper'

describe ProductBuildList do
  before { stub_symlink_methods }

  let(:pbl) { FactoryGirl.build(:product_build_list) }

  context 'ensures that validations and associations exist' do
    before do
      arch = double(:arch, id: 123, name: 'x86_64')
      allow(Arch).to receive(:find_by).with(name: 'x86_64').and_return(arch)
    end

    it 'is valid given valid attributes' do
      arch = FactoryGirl.create(:arch, name: 'x86_64')
      allow(Arch).to receive(:find_by).with(name: 'x86_64').and_return(arch)
      expect(FactoryGirl.create(:product_build_list)).to be_truthy
    end

    it { is_expected.to belong_to(:product) }

    it { is_expected.to validate_length_of(:main_script).is_at_most(255) }
    it { is_expected.to validate_length_of(:params).is_at_most(255) }

    it { is_expected.to validate_presence_of(:product_id) }
    it { is_expected.to validate_presence_of(:status) }

    ProductBuildList::STATUSES.each do |value|
      it { is_expected.to allow_value(value).for(:status) }
    end

    it { is_expected.to_not allow_value(555).for(:status) }

    it { is_expected.to have_readonly_attribute(:product_id) }
  end

  describe '#abf_worker_srcpath' do
    it 'returns URL to project archive' do
      expect(pbl.send :abf_worker_srcpath).to be_present
    end
  end

  describe '#abf_worker_params' do
    let(:pbl) { FactoryGirl.build(:product_build_list, id: 1234, params: 'ARCH=x86') }

    it 'returns String with params' do
      expect(pbl.send :abf_worker_params).to eq "BUILD_ID=#{pbl.id} PROJECT=#{pbl.project.name_with_owner} PROJECT_VERSION=#{pbl.project_version} COMMIT_HASH=#{pbl.commit_hash} ARCH=x86"
    end
  end

  describe '#abf_worker_args' do
    it 'returns Hash with args' do
      expect(pbl.send :abf_worker_args).to be_present
    end
  end
end
