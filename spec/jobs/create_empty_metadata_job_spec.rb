require 'spec_helper'

describe CreateEmptyMetadataJob do

  before  { stub_symlink_methods }
  subject { BuildLists::CleanBuildrootJob }

  context 'create_empty_metadata' do
    let(:job)         { CreateEmptyMetadataJob.new }
    let(:platform)    { FactoryGirl.build(:platform) }
    let(:path)        { platform.path }

    it 'creates metadata for rhel platform' do
      platform.distrib_type = 'rhel'
      job.send :create_empty_metadata, platform, path.dup

      expect(Dir["#{ path }/repodata/*"]).to    be_present
      expect(Dir["#{ path }/media_info/*"]).to  be_empty
    end

    it 'creates metadata for mdv platform' do
      platform.distrib_type = 'mdv'
      job.send :create_empty_metadata, platform, path.dup

      expect(Dir["#{ path }/media_info/*"]).to  be_present
      expect(Dir["#{ path }/repodata/*"]).to    be_empty
    end

    it 'does nothing for other platforms' do
      platform.distrib_type = 'test'
      job.send :create_empty_metadata, platform, path.dup

      expect(Dir["#{ path }/media_info/*"]).to  be_empty
      expect(Dir["#{ path }/repodata/*"]).to    be_empty
    end
  end

  context 'create_empty_metadata_for_repository' do
    let(:job)         { CreateEmptyMetadataJob.new }
    let(:repository)  { FactoryGirl.build(:repository) }
    let(:platform)    { repository.platform }

    before do
      allow(job).to receive(:arch_names).and_return(%w(i586 x86_64))
    end

    it 'repository of main platform' do
      paths = <<-STR
        #{ platform.path }/repository/i586/#{ repository.name }/release
        #{ platform.path }/repository/i586/#{ repository.name }/updates
        #{ platform.path }/repository/x86_64/#{ repository.name }/release
        #{ platform.path }/repository/x86_64/#{ repository.name }/updates
      STR
      paths.split("\n").each do |path|
        expect(job).to receive(:create_empty_metadata).with(platform, path.strip)
      end

      job.send :create_empty_metadata_for_repository, repository
    end

    it 'repository of personal platform' do
      platform.platform_type = Platform::TYPE_PERSONAL
      Platform.stub_chain(:main, :opened).and_return([platform])
      paths = <<-STR
        #{ platform.path }/repository/#{ platform.name }/i586/#{ repository.name }/release
        #{ platform.path }/repository/#{ platform.name }/i586/#{ repository.name }/updates
        #{ platform.path }/repository/#{ platform.name }/x86_64/#{ repository.name }/release
        #{ platform.path }/repository/#{ platform.name }/x86_64/#{ repository.name }/updates
      STR
      paths.split("\n").each do |path|
        expect(job).to receive(:create_empty_metadata).with(platform, path.strip)
      end

      job.send :create_empty_metadata_for_repository, repository
    end
  end

  context 'create_empty_metadata_for_platform' do
    let(:platform)    { FactoryGirl.build(:platform, id: 123) }
    let(:repository1) { FactoryGirl.build(:personal_repository) }
    let(:repository2) { FactoryGirl.build(:personal_repository) }
    let(:job)         { CreateEmptyMetadataJob.new('Platform', 123) }

    before do
      Platform.stub_chain(:main, :opened, :find).and_return(platform)
      Repository.stub_chain(:joins, :where, :find_each).and_yield(repository1).and_yield(repository2)
    end

    it 'creates metadata for all personal repositories' do
      expect(job).to receive(:create_empty_metadata_for_repository).with(repository1)
      expect(job).to receive(:create_empty_metadata_for_repository).with(repository2)

      job.send :create_empty_metadata_for_platform
    end
  end

end
