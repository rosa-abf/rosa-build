require 'spec_helper'

describe Subscribe do
  before(:each) { stub_symlink_methods }

  context 'validates that subscribe contains user' do

    it 'when subscribe contains user' do
      s = FactoryGirl.build(:subscribe)
      expect(s.valid?).to be_truthy
    end

    it 'when subscribe does not contains user' do
      s = FactoryGirl.build(:subscribe)
      s.user = nil
      expect(s.valid?).to be_falsy
    end
  end
end
