require 'spec_helper'

describe ProjectToRepository do
  before(:each) do
    stub_rsync_methods
    @platform = Factory(:platform)
    @first_repo = Factory(:repository, :platform_id => @platform.id)
    @second_repo = Factory(:repository, :platform_id => @platform.id)
    @project = Factory(:project)
    @first_repo.projects << @project
    @first_repo.save
  end

  it 'should not add the same project in different repositories of same platform' do
    p2r = @second_repo.project_to_repositories.build :project_id => @project.id
    p2r.should_not be_valid
  end
end
