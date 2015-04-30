require 'spec_helper'

RSpec.describe PullRequestPolicy, type: :policy do
  let(:pull_request) { FactoryGirl.build(:pull_request) }
  let(:user)  { FactoryGirl.create(:user) }
  subject { described_class }

  permissions :index? do
    it "grants access to anonymous user" do
      expect(subject).to permit(User.new, pull_request)
    end
  end

  %i(show? read? commits? files? create?).each do |perm|
    permissions perm do
      it "denies access if user can not read a project" do
        allow_any_instance_of(ProjectPolicy).to receive(:show?).and_return(false)
        expect(subject).to_not permit(User.new, pull_request)
      end

      context "user can read a project" do
        before do
          allow_any_instance_of(ProjectPolicy).to receive(:show?).and_return(true)
        end

        it "grants access" do
          expect(subject).to permit(User.new, pull_request)
        end
      end

      it "grants access for to global admin" do
        expect(subject).to permit(FactoryGirl.create(:admin), pull_request)
      end
    end
  end

  permissions :update? do
    it "denies access to anonymous user" do
      expect(subject).to_not permit(User.new, pull_request)
    end

    it "denies access to user" do
      expect(subject).to_not permit(user, pull_request)
    end

    it "grants access for writer of project" do
      allow_any_instance_of(PullRequestPolicy).to receive(:local_writer?).and_return(true)
      expect(subject).to permit(user, pull_request)
    end

    it "grants access to issue owner" do
      pull_request.user.save!
      expect(subject).to permit(pull_request.user, pull_request)
    end

    it "grants access for to global admin" do
      expect(subject).to permit(FactoryGirl.create(:admin), pull_request)
    end
  end

  permissions :merge? do
    it "denies access to anonymous user" do
      expect(subject).to_not permit(User.new, pull_request)
    end

    it "denies access to user" do
      expect(subject).to_not permit(user, pull_request)
    end

    it "grants access for writer of project" do
      allow_any_instance_of(PullRequestPolicy).to receive(:local_writer?).and_return(true)
      expect(subject).to permit(user, pull_request)
    end

    it "grants access for to global admin" do
      expect(subject).to permit(FactoryGirl.create(:admin), pull_request)
    end
  end

end
