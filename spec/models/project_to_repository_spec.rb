require 'spec_helper'

describe ProjectToRepository do
  before(:each) do
    stub_symlink_methods
    @platform = FactoryGirl.create(:platform)
    @first_repo = FactoryGirl.create(:repository, platform_id: @platform.id)
    @second_repo = FactoryGirl.create(:repository, platform_id: @platform.id)
    @project = FactoryGirl.create(:project)
    @first_repo.projects << @project
    @first_repo.save
  end

  it 'should not add the same project in different repositories of same platform' do
    p2r = @second_repo.project_to_repositories.build project_id: @project.id
    p2r.should_not be_valid
  end

  it 'creates task for removing project from repository on destroy' do
    @first_repo.project_to_repositories.destroy_all
    queue = @redis_instance.lrange(AbfWorker::BuildListsPublishTaskManager::PROJECTS_FOR_CLEANUP, 0, -1)
    queue.should have(2).item
    key = "#{@project.id}-#{@first_repo.id}-#{@platform.id}"
    queue.should include(key, "testing-#{key}")
  end
end
