require 'spec_helper'

describe BuildList do
  before { stub_symlink_methods }

  context 'validates that repository contains project' do
    it 'when repository contains project' do
      bl = FactoryGirl.build(:build_list)
      bl.valid?.should be_true
    end
    it 'when repository does not contain project' do
      bl = FactoryGirl.build(:build_list)
      bl.project.repositories = []
      bl.valid?.should be_false
    end
  end

  context "#notify_users" do
    let!(:user) { FactoryGirl.create(:user) }
    let!(:build_list) { FactoryGirl.create(:build_list,
                                           user: user,
                                           auto_publish: false) }
    let!(:build_list_package) { FactoryGirl.create(:build_list_package,
                                                   build_list: build_list,
                                                   project: build_list.project) }


    before(:all) { ActionMailer::Base.deliveries = [] }
    before do
      build_list.update_attributes({commit_hash: build_list.project.repo.commits('master').last.id,
        status: BuildList::BUILD_STARTED}, without_protection: true)
    end
    after { ActionMailer::Base.deliveries = [] }

    shared_examples_for 'build list notifications by email' do
      it "gets notification by email when status - Build complete" do
        build_list.build_success
        should have(1).item
      end

      it "gets notification by email when status - Build error" do
        build_list.build_error
        should have(1).item
      end

      it "gets notification by email when auto_publish and status - Build error" do
        build_list.update_attributes(auto_publish: true)
        build_list.build_error
        should have(1).item
      end

      it "gets notification by email when status - Failed publish" do
        build_list.update_attributes({status: BuildList::BUILD_PUBLISH}, without_protection: true)
        build_list.fail_publish
        should have(1).item
      end

      it "gets notification by email when auto_publish and status - Failed publish" do
        build_list.update_attributes({auto_publish: true, status: BuildList::BUILD_PUBLISH}, without_protection: true)
        build_list.fail_publish
        should have(1).item
      end

      it "gets notification by email when status - Build published" do
        build_list.update_attributes({status: BuildList::BUILD_PUBLISH}, without_protection: true)
        build_list.published
        should have(1).item
      end

      it "gets notification by email when auto_publish and status - Build published" do
        build_list.update_attributes({auto_publish: true, status: BuildList::BUILD_PUBLISH}, without_protection: true)
        build_list.published
        should have(1).item
      end

      it "doesn't get notification by email when auto_publish and status - Build complete" do
        build_list.update_attributes(auto_publish: true)
        build_list.build_success
        should have(:no).items
      end

      it "doesn't get notification by email when mass build" do
        build_list.update_attributes({mass_build_id: 1, status: BuildList::BUILD_PUBLISH}, without_protection: true)
        build_list.published
        should have(:no).items
      end

      it "doesn't get notification by email when notification by email has been disabled" do
        notifier.update_attributes(can_notify: false)
        build_list.build_success
        should have(:no).items
      end
    end

    subject { ActionMailer::Base.deliveries }

    context "user created build task" do
      let!(:notifier) { user.notifier }
      before do
        notifier.update_attributes(new_associated_build: false)
        build_list.project.owner.notifier.update_attributes(can_notify: false)
      end

      it_should_behave_like 'build list notifications by email'

      it "doesn't get notification by email when 'build list' notifications has been disabled" do
        notifier.update_attributes(new_build: false)
        build_list.build_success
        should have(:no).items
      end

      it "doesn't get notification by email when 'build list' notifications - enabled, email notifications - disabled" do
        notifier.update_attributes(can_notify: false, new_build: true)
        build_list.build_success
        should have(:no).items
      end
    end

    context "build task has been created and associated user" do
      let!(:notifier) { build_list.project.owner.notifier }
      before do
        notifier.update_attributes(new_build: false)
        user.notifier.update_attributes(can_notify: false)
      end

      it_should_behave_like 'build list notifications by email'

      it "doesn't get notification by email when 'associated build list' notifications has been disabled" do
        notifier.update_attributes(new_associated_build: false)
        build_list.build_success
        should have(:no).items
      end

      it "doesn't get notification by email when 'associated build list' notifications - enabled, email notifications - disabled" do
        notifier.update_attributes(can_notify: false, new_associated_build: true)
        build_list.build_success
        should have(:no).items
      end
    end

    it "doesn't get 2 notification by email when user associated to project and created task" do
      project = FactoryGirl.create(:project_with_commit, owner: user)
      bl = FactoryGirl.create(:build_list_with_attaching_project,
        user: user,
        auto_publish: true,
        project: project
      )
      FactoryGirl.create(:build_list_package, build_list: bl, project: bl.project)
      bl.update_attributes({commit_hash: bl.project.repo.commits('master').last.id,
        status: BuildList::BUILD_PUBLISH}, without_protection: true)
      bl.published
      should have(1).item
    end

  end # notify_users

  context '#has_new_packages?' do
    let!(:build_list) { FactoryGirl.create( :build_list,
                                            status: BuildList::SUCCESS,
                                            auto_publish: true) }
    let!(:build_list_package) { FactoryGirl.create( :build_list_package,
                                                    build_list: build_list,
                                                    version: '3.1.12',
                                                    release: 6,
                                                    platform: build_list.save_to_platform,
                                                    project: build_list.project) }
    let!(:published_build_list) { FactoryGirl.create( :build_list,
                                                      project: build_list.project,
                                                      status: BuildList::BUILD_PUBLISHED,
                                                      save_to_platform: build_list.save_to_platform,
                                                      arch: build_list.arch) }
    let!(:published_build_list_package) { FactoryGirl.create( :build_list_package,
                                                              build_list: published_build_list,
                                                              platform: published_build_list.save_to_platform,
                                                              actual: true,
                                                              version: '3.1.12',
                                                              release: 6,
                                                              project: published_build_list.project) }

    it 'ensures that return false if version of packages are same and platform is released' do
      build_list.save_to_platform.update_attributes(released: true)
      build_list.has_new_packages?.should be_false
    end

    it 'ensures that return true if version of packages are same and platform is not released' do
      build_list.has_new_packages?.should be_true
    end

    context 'ensures that return false if version of published package >' do

      it 'published: 3.1.13, new: 3.1.12' do
        published_build_list_package.update_attributes(version: '3.1.13')
        build_list.has_new_packages?.should be_false
      end

      it 'published: 3.1.12, new: 3.0.999' do
        build_list_package.update_attributes(version: '3.0.999')
        build_list.has_new_packages?.should be_false
      end

      it 'published: 3.0.0, new: 3.0.rc1' do
        published_build_list_package.update_attributes(version: '3.0.0')
        build_list_package.update_attributes(version: '3.0.rc1')
        build_list.has_new_packages?.should be_false
      end

    end

    context 'ensures that return true if version of published package <' do

      it 'published: 3.1.11, new: 3.1.12' do
        published_build_list_package.update_attributes(version: '3.1.11')
        build_list.has_new_packages?.should be_true
      end

      it 'published: 3.0.999, new: 3.1.12' do
        published_build_list_package.update_attributes(version: '3.0.999')
        build_list.has_new_packages?.should be_true
      end

      it 'published: 3.0.rc1, new: 3.0.0' do
        published_build_list_package.update_attributes(version: '3.0.rc1')
        build_list_package.update_attributes(version: '3.0.0')
        build_list.has_new_packages?.should be_true
      end

    end

    it 'ensures that return true if release of published package <' do
      published_build_list_package.update_attributes(release: 5)
      build_list.has_new_packages?.should be_true
    end

  end

end
