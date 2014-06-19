require 'spec_helper'

describe ProjectToRepository do
  let(:platform)    { FactoryGirl.create(:platform) }
  let(:first_repo)  { FactoryGirl.create(:repository, platform: platform) }
  let(:second_repo) { FactoryGirl.create(:repository, platform: platform) }
  let(:project)     { FactoryGirl.create(:project) }

  before do
    stub_symlink_methods
    first_repo.projects << project
    first_repo.save
  end

  it 'should not add the same project in different repositories of same platform' do
    p2r = second_repo.project_to_repositories.build project: project
    expect(p2r).to_not be_valid
  end

  it 'creates task for removing project from repository on destroy' do
    expect(Resque).to receive(:enqueue).with(DestroyProjectFromRepositoryJob, project.id, first_repo.id)
    first_repo.project_to_repositories.destroy_all
  end
end
