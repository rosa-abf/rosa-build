require 'spec_helper'

describe ActivityFeed do

  it 'is valid given valid attributes' do
    FactoryGirl.build(:activity_feed).should be_valid
  end

end
