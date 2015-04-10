require 'spec_helper'

RSpec.describe GroupPolicy, type: :policy do
  let(:group) { FactoryGirl.build(:group) }
  let(:user)  { FactoryGirl.create(:user) }
  subject { described_class }


  %i(index? create? remove_user?).each do |perm|
    permissions perm do
      it "denies access to anonymous user" do
        expect(subject).to_not permit(User.new, group)
      end

      it "grants access to user" do
        expect(subject).to permit(user, group)
      end
    end
  end

  permissions :show? do
    it "grants access to anonymous user" do
      expect(subject).to permit(User.new, group)
    end
  end

  permissions :reader? do
    it "denies access to anonymous user" do
      expect(subject).to_not permit(User.new, group)
    end

    it "denies access to user" do
      expect(subject).to_not permit(user, group)
    end

    it "grants access to group reader" do
      allow_any_instance_of(GroupPolicy).to receive(:local_reader?).and_return(true)
      expect(subject).to permit(user, group)
    end
  end

  permissions :write? do
    it "denies access to anonymous user" do
      expect(subject).to_not permit(User.new, group)
    end

    it "denies access to user" do
      expect(subject).to_not permit(user, group)
    end

    it "grants access to group writer" do
      allow_any_instance_of(GroupPolicy).to receive(:local_writer?).and_return(true)
      expect(subject).to permit(user, group)
    end
  end

  %i(update? add_member? manage_members? members? remove_member? remove_members? update_member?).each do |perm|
    permissions perm do
      it "denies access to anonymous user" do
        expect(subject).to_not permit(User.new, group)
      end

      it "denies access to user" do
        expect(subject).to_not permit(user, group)
      end

      it "grants access to group owner" do
        group.save!
        expect(subject).to permit(group.owner, group)
      end

      it "grants access to group admin" do
        allow_any_instance_of(GroupPolicy).to receive(:local_admin?).and_return(true)
        expect(subject).to permit(user, group)
      end

      it "grants access for to global admin" do
        expect(subject).to permit(FactoryGirl.create(:admin), group)
      end
    end
  end

  permissions :destroy? do
    it "denies access to anonymous user" do
      expect(subject).to_not permit(User.new, group)
    end

    it "denies access to user" do
      expect(subject).to_not permit(user, group)
    end

    it "denies access to group admin" do
      allow_any_instance_of(GroupPolicy).to receive(:local_admin?).and_return(true)
      expect(subject).to_not permit(user, group)
    end

    it "grants access to group owner" do
      group.save!
      expect(subject).to permit(group.owner, group)
    end

    it "grants access for to global admin" do
      expect(subject).to permit(FactoryGirl.create(:admin), group)
    end
  end

end
