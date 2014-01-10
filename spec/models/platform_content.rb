# -*- encoding : utf-8 -*-
require 'spec_helper'

describe PlatformContent do
  subject { PlatformContent }

  before { stub_symlink_methods }
  let!(:platform) { FactoryGirl.create(:platform) }

  context '#find_by_platform' do
    before do
      File.open(File.join(platform.path, 'test001'), "w")
      File.open(File.join(platform.path, 'test002'), "w")
    end

    it 'ensures that finds files' do
      # + /repository folder
      subject.find_by_platform(platform, '', '').should have(3).items
    end

    context 'ensures that finds files by name' do
      it { subject.find_by_platform(platform, '', 'test').should            have(2).items }
      it { subject.find_by_platform(platform, '', 'test001').should         have(1).item }
      it { subject.find_by_platform(platform, 'repository', 'test').should  have(:no).items }
    end

  end

  context '#is_folder?' do
    it 'ensures that returns true for folder' do
      subject.find_by_platform(platform, '', 'repository').first.is_folder?
             .should be_true
    end

    it 'ensures that returns false for file' do
      File.open(File.join(platform.path, 'test001'), "w")
      subject.find_by_platform(platform, '', 'test').first.is_folder?
             .should be_false
    end
  end

  context '#build_list' do
    let!(:package)    { FactoryGirl.create(:build_list_package, :actual => true) }
    let(:platform)    { package.build_list.save_to_platform }
    let(:repository)  { platform.repositories.first }

    before do
      File.open(File.join(platform.path, 'test001'), "w")

      package.build_list.update_column(:status, BuildList::BUILD_PUBLISHED)
      path = File.join platform.path, 'repository', 'SRPMS', repository.name, 'release'
      FileUtils.mkdir_p path
      File.open(File.join(path, package.fullname), "w")

      path = File.join path, 'repodata'
      FileUtils.mkdir_p path
      File.open(File.join(path, package.fullname), "w")
    end

    context 'ensures that returns nil for simple file' do
      it { subject.find_by_platform(platform, '', 'test').first.build_list.should be_nil }
      it { subject.find_by_platform(platform, "repository/SRPMS/#{repository.name}/release/repodata", '').first.build_list.should be_nil }
    end

    it 'ensures that returns build_list for package' do
      subject.find_by_platform(platform, "repository/SRPMS/#{repository.name}/release", package.fullname)
             .first.build_list.should == package.build_list
    end
  end

end
