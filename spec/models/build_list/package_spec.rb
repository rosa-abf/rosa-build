require 'spec_helper'

describe BuildList::Package do
  before { stub_symlink_methods; stub_redis }

  it 'is valid' do
    FactoryGirl.create(:build_list_package).should be_persisted
  end

  context '#set_epoch' do
    let(:package) { FactoryGirl.build(:build_list_package) }

    ['', '(none)'].each do |epoch|
      it "ensures that epoch is set to nil when epoch is '#{epoch}'" do
        package.epoch = epoch
        package.save
        package.epoch.should be_nil
      end

    end

    it "ensures that valid epoch has been setted" do
      package.epoch = '55'
      package.save
      package.epoch.should == 55
    end

  end

end
