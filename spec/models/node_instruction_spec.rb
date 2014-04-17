require 'spec_helper'

describe NodeInstruction do

  it 'is valid given valid attributes' do
    FactoryGirl.build(:node_instruction).should be_valid
  end

end
