require 'spec_helper'

describe BuildList::Package do
  before { stub_symlink_methods }

  it 'is valid' do
    expect(FactoryGirl.create(:build_list_package)).to be_persisted
  end


  describe '#set_epoch' do
    let(:package) { FactoryGirl.build(:build_list_package) }

    ['', '(none)'].each do |epoch|
      it "ensures that epoch is set to nil when epoch is '#{epoch}'" do
        package.epoch = epoch
        package.save
        expect(package.epoch).to be_nil
      end

    end

    it "ensures that valid epoch has been setted" do
      package.epoch = '55'
      package.save
      expect(package.epoch).to eq 55
    end

  end

  describe '#dependent_packages=' do
    it 'sets a packages' do
      package = FactoryGirl.build(:build_list_package, dependent_packages: 'x y z')
      expect(package).to be_valid
      expect(package.dependent_packages).to eq %w(x y z)
    end
  end
end
