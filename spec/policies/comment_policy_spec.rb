require 'spec_helper'

RSpec.describe CommentPolicy, type: :policy do
  let(:comment) { FactoryGirl.build(:comment) }
  subject { described_class }

  %i(create? new_line?).each do |perm|
    permissions perm do
      it "denies access to anonymous user" do
        expect(subject).to_not permit(User.new, comment)
      end

      it "denies access if user can not read a project" do
        allow_any_instance_of(ProjectPolicy).to receive(:show?).and_return(false)
        expect(subject).to_not permit(FactoryGirl.create(:user), comment)
      end

      it "grants access if user can read a project" do
        allow_any_instance_of(ProjectPolicy).to receive(:show?).and_return(true)
        expect(subject).to permit(FactoryGirl.create(:user), comment)
      end
    end
  end

  %i(update? destroy?).each do |perm|
    permissions perm do
      it "denies access to user" do
        expect(subject).to_not permit(User.new, comment)
      end

      it "grants access for creator" do
        expect(subject).to permit(comment.user, comment)
      end

      it "grants access for admin of project" do
        allow_any_instance_of(CommentPolicy).to receive(:local_admin?).
          with(comment.project).and_return(true)
        expect(subject).to permit(User.new, comment)
      end

      it "grants access for to global admin" do
        expect(subject).to permit(FactoryGirl.build(:admin), comment)
      end
    end
  end

end
