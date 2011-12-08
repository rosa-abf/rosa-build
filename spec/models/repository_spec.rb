require 'spec_helper'

describe Repository do

  context 'when create with same owner that platform' do
    before (:each) do
      @platform = Factory(:platform)
      @params = {:name => 'tst_platform', :description => 'test platform'}
    end

    it 'it should increase Relations.count by 1' do
      rep = Repository.new(@params)
      rep.platform = @platform
      rep.owner = @platform.owner
      rep.save!
      Relation.by_object(rep.owner).by_target(rep).count.should eql(1)
#      (@platform.owner.repositories.where(:platform_id => @platform.id).count == 1).should be_true
    end
  end
  #pending "add some examples to (or delete) #{__FILE__}"
end
