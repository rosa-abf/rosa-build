# -*- encoding : utf-8 -*-
require 'spec_helper'

describe Repository do

  context 'when create with same owner that platform' do
    before (:each) do
      stub_rsync_methods
      @platform = Factory(:platform)
      @params = {:name => 'tst_platform', :description => 'test platform'}
    end

    it 'it should increase Repository.count by 1' do
      rep = Repository.create(@params) {|r| r.platform = @platform}
      @platform.repositories.count.should eql(1)
    end
  end
end
