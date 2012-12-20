# -*- encoding : utf-8 -*-
require 'spec_helper'

describe BuildList do

  context "#notify_users" do
    before { stub_symlink_methods }
    let!(:user) { FactoryGirl.create(:user) }
    let!(:build_list) { FactoryGirl.create(:build_list_core,
                                           :user => user,
                                           :auto_publish => false) }
    let!(:build_list_package) { FactoryGirl.create(:build_list_package,
                                                   :build_list => build_list,
                                                   :project => build_list.project) }


    before(:all) { ActionMailer::Base.deliveries = [] }
    before do
      build_list.update_attributes(:commit_hash => build_list.project.repo.commits('master').last.id,
        :status => BuildServer::BUILD_STARTED,)
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
        build_list.update_attributes(:auto_publish => true)
        build_list.build_error
        should have(1).item
      end

      it "gets notification by email when status - Failed publish" do
        build_list.update_attributes(:status => BuildList::BUILD_PUBLISH)
        build_list.fail_publish
        should have(1).item
      end

      it "gets notification by email when auto_publish and status - Failed publish" do
        build_list.update_attributes(:auto_publish => true, :status => BuildList::BUILD_PUBLISH)
        build_list.fail_publish
        should have(1).item
      end

      it "gets notification by email when status - Build published" do
        build_list.update_attributes(:status => BuildList::BUILD_PUBLISH)
        build_list.published
        should have(1).item
      end

      it "gets notification by email when auto_publish and status - Build published" do
        build_list.update_attributes(:auto_publish => true, :status => BuildList::BUILD_PUBLISH)
        build_list.published
        should have(1).item
      end

      it "doesn't get notification by email when auto_publish and status - Build complete" do
        build_list.update_attributes(:auto_publish => true)
        build_list.build_success
        should have(:no).items
      end

      it "doesn't get notification by email when mass build" do
        build_list.update_attributes(:mass_build_id => 1, :status => BuildList::BUILD_PUBLISH)
        build_list.published
        should have(:no).items
      end

      it "doesn't get notification by email when notification by email has been disabled" do
        notifier.update_attributes(:can_notify => false)
        build_list.build_success
        should have(:no).items
      end
    end

    subject { ActionMailer::Base.deliveries }

    context "user created build task" do
      let!(:notifier) { user.notifier }
      before do
        notifier.update_attributes(:new_associated_build => false)
        build_list.project.owner.notifier.update_attributes(:can_notify => false)
      end

      it_should_behave_like 'build list notifications by email'

      it "doesn't get notification by email when 'build list' notifications has been disabled" do
        notifier.update_attributes(:new_build => false)
        build_list.build_success
        should have(:no).items
      end

      it "doesn't get notification by email when 'build list' notifications - enabled, email notifications - disabled" do
        notifier.update_attributes(:can_notify => false, :new_build => true)
        build_list.build_success
        should have(:no).items
      end
    end

    context "build task has been created and associated user" do
      let!(:notifier) { build_list.project.owner.notifier }
      before do
        notifier.update_attributes(:new_build => false)
        user.notifier.update_attributes(:can_notify => false)
      end

      it_should_behave_like 'build list notifications by email'

      it "doesn't get notification by email when 'associated build list' notifications has been disabled" do
        notifier.update_attributes(:new_associated_build => false)
        build_list.build_success
        should have(:no).items
      end

      it "doesn't get notification by email when 'associated build list' notifications - enabled, email notifications - disabled" do
        notifier.update_attributes(:can_notify => false, :new_associated_build => true)
        build_list.build_success
        should have(:no).items
      end
    end

    it "doesn't get 2 notification by email when user associated to project and created task" do
      bl = FactoryGirl.create(:build_list_core,
        :user => user,
        :auto_publish => true,
        :project => FactoryGirl.create(:project_with_commit, :owner => user))
      FactoryGirl.create(:build_list_package, :build_list => bl, :project => bl.project)
      bl.update_attributes(:commit_hash => bl.project.repo.commits('master').last.id,
        :status => BuildList::BUILD_PUBLISH)
      bl.published
      should have(1).item
    end

  end # notify_users

end
