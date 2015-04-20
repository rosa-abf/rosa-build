require 'spec_helper'

describe ProductBuildList do
  before { stub_symlink_methods }

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
    #it { should_not allow_mass_assignment_of(:product_id) }

    it { is_expected.to allow_mass_assignment_of(:status) }
    it { is_expected.to allow_mass_assignment_of(:base_url) }
  end
end
