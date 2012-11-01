require 'spec_helper'

describe BuildListObserver do

  context "notify users" do
    let!(:user) { FactoryGirl.create(:user) }
    let!(:build_list) { FactoryGirl.create(:build_list, :user => user, :auto_publish => false) }

    before(:all) { ActionMailer::Base.deliveries = [] }
    before { build_list.update_attribute(:status, BuildServer::BUILD_STARTED) }
    after { ActionMailer::Base.deliveries = [] }

    shared_examples_for 'build list notifications by email' do
      it "gets notification by email when status - Build complete" do
        build_list.update_attribute(:status, BuildServer::SUCCESS)
        should have(1).item
      end

      it "gets notification by email when status - Build published" do
        build_list.update_attribute(:status, BuildList::BUILD_PUBLISHED)
        should have(1).item
      end

      it "gets notification by email when auto_publish and status - Build published" do
        build_list.update_attributes(:auto_publish => true, :status => BuildList::BUILD_PUBLISHED)
        should have(1).item
      end

      it "doesn't get notification by email when auto_publish and status - Build complete" do
        build_list.update_attributes(:auto_publish => true, :status => BuildServer::SUCCESS)
        should have(:no).items
      end

      it "doesn't get notification by email when mass build" do
        build_list.update_attributes(:mass_build_id => 1, :status => BuildList::BUILD_PUBLISHED)
        should have(:no).items
      end

      it "doesn't get notification by email when notification by email has been disabled" do
        notifier.update_attribute(:can_notify, false)
        build_list.update_attribute(:status, BuildServer::SUCCESS)
        should have(:no).items
      end
    end

    subject { ActionMailer::Base.deliveries }

    context "user created build task" do
      let!(:notifier) { user.notifier }
      before do
        notifier.update_attribute(:new_associated_build, false)
        build_list.project.owner.notifier.update_attribute(:can_notify, false)
      end

      it_should_behave_like 'build list notifications by email'

      it "doesn't get notification by email when 'build list' notifications has been disabled" do
        notifier.update_attribute(:new_build, false)
        build_list.update_attribute(:status, BuildServer::SUCCESS)
        should have(:no).items
      end

      it "doesn't get notification by email when 'build list' notifications - enabled, email notifications - disabled" do
        notifier.update_attributes(:can_notify => false, :new_build => true)
        build_list.update_attribute(:status, BuildServer::SUCCESS)
        should have(:no).items
      end
    end

    context "build task has been created and associated user" do
      let!(:notifier) { build_list.project.owner.notifier }
      before do
        notifier.update_attribute(:new_build, false)
        user.notifier.update_attribute(:can_notify, false)
      end

      it_should_behave_like 'build list notifications by email'

      it "doesn't get notification by email when 'associated build list' notifications has been disabled" do
        notifier.update_attribute(:new_associated_build, false)
        build_list.update_attribute(:status, BuildServer::SUCCESS)
        should have(:no).items
      end

      it "doesn't get notification by email when 'associated build list' notifications - enabled, email notifications - disabled" do
        notifier.update_attributes(:can_notify => false, :new_associated_build => true)
        build_list.update_attribute(:status, BuildServer::SUCCESS)
        should have(:no).items
      end
    end

  end # notify users

end
