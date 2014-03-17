require 'spec_helper'

describe Arch do

  it 'is valid given valid attributes' do
    FactoryGirl.build(:arch).should be_valid
  end

end
