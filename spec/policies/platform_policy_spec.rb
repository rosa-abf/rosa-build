require 'spec_helper'

RSpec.describe PlatformPolicy, type: :policy do
  let(:platform) { FactoryGirl.build(:platform) }
  subject { described_class }

  permissions :index? do
    it "denies access to anonymous user" do
      expect(subject).to_not permit(User.new, :platform)
    end

    it "grants access to user" do
      expect(subject).to permit(FactoryGirl.create(:user), :platform)
    end
  end


  %i(allowed? platforms_for_build?).each do |perm|
    permissions perm do
      it "grants access to anonymous user" do
        expect(subject).to permit(User.new, :platform)
      end
    end
  end

  %i(show? advisories? owned? read? related?).each do |perm|
    permissions perm do
      context 'open platform' do
        it "grants access to anonymous user" do
          expect(subject).to permit(User.new, platform)
        end
      end

      context 'hidden platform' do
        before do
          platform.visibility = Platform::VISIBILITY_HIDDEN
        end

        it "denies access to anonymous user" do
          expect(subject).to_not permit(User.new, platform)
        end

        it "grants access for reader of platform" do
          allow_any_instance_of(PlatformPolicy).to receive(:local_reader?).and_return(true)
          expect(subject).to permit(User.new, platform)
        end

        it "grants access for owner of platform" do
          allow_any_instance_of(PlatformPolicy).to receive(:owner?).and_return(true)
          expect(subject).to permit(User.new, platform)
        end

        it "grants access for reader of repository" do
          allow_any_instance_of(PlatformPolicy).to receive(:user_platform_ids).and_return([platform.id])
          expect(subject).to permit(User.new, platform)
        end

        it "grants access for to global admin" do
          expect(subject).to permit(FactoryGirl.build(:admin), platform)
        end
      end
    end
  end

  permissions :members? do
    context 'open platform' do
      it "grants access to anonymous user" do
        expect(subject).to permit(User.new, platform)
      end
    end

    context 'hidden platform' do
      before do
        platform.visibility = Platform::VISIBILITY_HIDDEN
      end

      it "denies access to anonymous user" do
        expect(subject).to_not permit(User.new, platform)
      end

      it "grants access for reader of platform" do
        allow_any_instance_of(PlatformPolicy).to receive(:local_reader?).and_return(true)
        expect(subject).to permit(User.new, platform)
      end

      it "grants access for owner of platform" do
        allow_any_instance_of(PlatformPolicy).to receive(:owner?).and_return(true)
        expect(subject).to permit(User.new, platform)
      end

      it "grants access for to global admin" do
        expect(subject).to permit(FactoryGirl.build(:admin), platform)
      end
    end
  end

  permissions :create? do
    it "denies access to user" do
      expect(subject).to_not permit(User.new, :platform)
    end

    it "grants access for to global admin" do
      expect(subject).to permit(FactoryGirl.build(:admin), :platform)
    end
  end

  permissions :update? do
    it "denies access to user" do
      expect(subject).to_not permit(User.new, platform)
    end

    it "grants access for owner of platform" do
      allow_any_instance_of(PlatformPolicy).to receive(:owner?).and_return(true)
      expect(subject).to permit(User.new, platform)
    end

    it "grants access for to global admin" do
      expect(subject).to permit(FactoryGirl.build(:admin), platform)
    end
  end

  permissions :destroy? do
    it "denies access to user" do
      expect(subject).to_not permit(User.new, platform)
    end

    it "grants access for owner of platform" do
      allow_any_instance_of(PlatformPolicy).to receive(:owner?).and_return(true)
      expect(subject).to permit(User.new, platform)
    end

    it "grants access for to global admin" do
      expect(subject).to permit(FactoryGirl.build(:admin), platform)
    end

    context 'personal platform' do
      let(:platform) { FactoryGirl.build(:personal_platform) }

      it "denies access for owner of platform" do
        allow_any_instance_of(PlatformPolicy).to receive(:owner?).and_return(true)
        expect(subject).to_not permit(User.new, platform)
      end

      it "denies access for to global admin" do
        expect(subject).to_not permit(FactoryGirl.build(:admin), platform)
      end
    end
  end

  %i(local_admin_manage? add_project? remove_file?).each do |perm|
    permissions perm do
      it "denies access to user" do
        expect(subject).to_not permit(User.new, platform)
      end

      it "grants access for admin of platform" do
        allow_any_instance_of(PlatformPolicy).to receive(:local_admin?).and_return(true)
        expect(subject).to permit(User.new, platform)
      end

      it "grants access for owner of platform" do
        allow_any_instance_of(PlatformPolicy).to receive(:owner?).and_return(true)
        expect(subject).to permit(User.new, platform)
      end

      it "grants access for to global admin" do
        expect(subject).to permit(FactoryGirl.build(:admin), platform)
      end
    end
  end

  %i(clone? make_clone?).each do |perm|
    permissions perm do
      it "denies access to user" do
        expect(subject).to_not permit(User.new, platform)
      end

      it "grants access for to global admin" do
        expect(subject).to permit(FactoryGirl.build(:admin), platform)
      end

      context 'personal platform' do
        let(:platform) { FactoryGirl.build(:personal_platform) }

        it "denies access for to global admin" do
          expect(subject).to_not permit(FactoryGirl.build(:admin), platform)
        end
      end
    end
  end

  %i(add_member? regenerate_metadata? remove_member? remove_members?).each do |perm|
    permissions perm do
      it "denies access to user" do
        expect(subject).to_not permit(User.new, platform)
      end

      it "grants access for admin of platform" do
        allow_any_instance_of(PlatformPolicy).to receive(:local_admin?).and_return(true)
        expect(subject).to permit(User.new, platform)
      end

      it "grants access for owner of platform" do
        allow_any_instance_of(PlatformPolicy).to receive(:owner?).and_return(true)
        expect(subject).to permit(User.new, platform)
      end

      it "grants access for to global admin" do
        expect(subject).to permit(FactoryGirl.build(:admin), platform)
      end

      context 'personal platform' do
        let(:platform) { FactoryGirl.build(:personal_platform) }

        it "denies access for admin of platform" do
          allow_any_instance_of(PlatformPolicy).to receive(:local_admin?).and_return(true)
          expect(subject).to_not permit(User.new, platform)
        end

        it "denies access for owner of platform" do
          allow_any_instance_of(PlatformPolicy).to receive(:owner?).and_return(true)
          expect(subject).to_not permit(User.new, platform)
        end

        it "denies access for to global admin" do
          expect(subject).to_not permit(FactoryGirl.build(:admin), platform)
        end
      end
    end
  end

  permissions :clear? do
    it "denies access to user" do
      expect(subject).to_not permit(User.new, platform)
    end

    it "denies access for owner of platform" do
      allow_any_instance_of(PlatformPolicy).to receive(:owner?).and_return(true)
      expect(subject).to_not permit(User.new, platform)
    end

    it "denies access for to global admin" do
      expect(subject).to_not permit(FactoryGirl.build(:admin), platform)
    end

    context 'personal platform' do
      let(:platform) { FactoryGirl.build(:personal_platform) }

      it "denies access to user" do
        expect(subject).to_not permit(User.new, platform)
      end

      it "grants access for owner of platform" do
        allow_any_instance_of(PlatformPolicy).to receive(:owner?).and_return(true)
        expect(subject).to permit(User.new, platform)
      end

      it "grants access for to global admin" do
        expect(subject).to permit(FactoryGirl.build(:admin), platform)
      end
    end
  end

end
