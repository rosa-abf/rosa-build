require 'spec_helper'

RSpec.describe IssuePolicy, type: :policy do
  let(:issue) { FactoryGirl.build(:issue) }
  let(:user)  { FactoryGirl.create(:user) }
  subject { described_class }

  permissions :index? do
    it "grants access to anonymous user" do
      expect(subject).to permit(User.new, issue)
    end
  end

  %i(show? create? read?).each do |perm|
    permissions perm do
      it "denies access if user can not read a project" do
        allow_any_instance_of(ProjectPolicy).to receive(:show?).and_return(false)
        expect(subject).to_not permit(User.new, issue)
      end

      context "user can read a project" do
        before do
          allow_any_instance_of(ProjectPolicy).to receive(:show?).and_return(true)
        end

        it "grants access" do
          expect(subject).to permit(User.new, issue)
        end

        it "denies access if project issues are disabled" do
          issue.project.has_issues = false
          expect(subject).to_not permit(User.new, issue)
        end
      end

    end
  end

  permissions :update? do
    it "denies access to anonymous user" do
      expect(subject).to_not permit(User.new, issue)
    end

    it "denies access to user" do
      expect(subject).to_not permit(user, issue)
    end

    it "grants access to project admin" do
      allow_any_instance_of(IssuePolicy).to receive(:local_admin?).with(issue.project).and_return(true)
      expect(subject).to permit(user, issue)
    end

    it "grants access to issue owner" do
      issue.save!
      expect(subject).to permit(issue.user, issue)
    end

    it "grants access for to global admin" do
      expect(subject).to permit(FactoryGirl.create(:admin), issue)
    end
  end

end
