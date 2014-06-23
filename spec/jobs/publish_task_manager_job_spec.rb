require 'spec_helper'

describe PublishTaskManagerJob do

  subject { PublishTaskManagerJob }

  it 'ensures that not raises error' do
    expect do
      subject.perform
    end.to_not raise_exception
  end
end
