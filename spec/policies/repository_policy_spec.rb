require 'spec_helper'

RSpec.describe RepositoryPolicy, type: :policy do
  let(:repository) { FactoryGirl.build(:repository) }
  subject { described_class }

  %i(show? projects? projects_list? read?).each do |perm|
    permissions perm do
      it "denies access if user can not show a platform" do
        allow_any_instance_of(PlatformPolicy).to receive(:show?).and_return(false)
        expect(subject).to_not permit(User.new, repository)
      end

      it "grants access if user can show a platform" do
        allow_any_instance_of(PlatformPolicy).to receive(:show?).and_return(true)
        expect(subject).to permit(User.new, repository)
      end

      it "grants access for to global admin" do
        expect(subject).to permit(FactoryGirl.build(:admin), repository)
      end
    end
  end

  permissions :reader? do
    it "denies access to user" do
      expect(subject).to_not permit(User.new, repository)
    end

    it "grants access for reader of platform" do
      allow_any_instance_of(RepositoryPolicy).to receive(:local_reader?).
        with(repository.platform).and_return(true)
      expect(subject).to permit(User.new, repository)
    end

    it "grants access for to global admin" do
      expect(subject).to permit(FactoryGirl.build(:admin), repository)
    end
  end

  permissions :write? do
    it "denies access to user" do
      expect(subject).to_not permit(User.new, repository)
    end

    it "grants access for writer of platform" do
      allow_any_instance_of(RepositoryPolicy).to receive(:local_writer?).
        with(repository.platform).and_return(true)
      expect(subject).to permit(User.new, repository)
    end

    it "grants access for to global admin" do
      expect(subject).to permit(FactoryGirl.build(:admin), repository)
    end
  end

  %i(update? manage_members? regenerate_metadata? signatures?).each do |perm|
    permissions perm do
      it "denies access to user" do
        expect(subject).to_not permit(User.new, repository)
      end

      it "grants access for admin of platform" do
        allow_any_instance_of(RepositoryPolicy).to receive(:local_admin?).
          with(repository.platform).and_return(true)
        expect(subject).to permit(User.new, repository)
      end

      it "grants access for to global admin" do
        expect(subject).to permit(FactoryGirl.build(:admin), repository)
      end
    end
  end

  %i(create? destroy?).each do |perm|
    permissions perm do
      it "denies access to user" do
        expect(subject).to_not permit(User.new, repository)
      end

      it "grants access for admin of platform" do
        allow_any_instance_of(RepositoryPolicy).to receive(:local_admin?).
          with(repository.platform).and_return(true)
        expect(subject).to permit(User.new, repository)
      end

      it "grants access for to global admin" do
        expect(subject).to permit(FactoryGirl.build(:admin), repository)
      end

      it "denies access for personal platform and repository with 'main' name" do
        repository.platform = FactoryGirl.build(:personal_platform)
        repository.name = 'main'
        expect(subject).to_not permit(FactoryGirl.build(:admin), repository)
      end
    end
  end

  %i(packages? remove_member? remove_members? add_member? sync_lock_file?).each do |perm|
    permissions perm do
      it "denies access to user" do
        expect(subject).to_not permit(User.new, repository)
      end

      it "grants access for admin of platform" do
        allow_any_instance_of(RepositoryPolicy).to receive(:local_admin?).
          with(repository.platform).and_return(true)
        expect(subject).to permit(User.new, repository)
      end

      it "grants access for to global admin" do
        expect(subject).to permit(FactoryGirl.build(:admin), repository)
      end

      it "denies access for personal platform" do
        repository.platform = FactoryGirl.build(:personal_platform)
        expect(subject).to_not permit(FactoryGirl.build(:admin), repository)
      end
    end
  end

  %i(add_project? remove_project?).each do |perm|
    permissions perm do
      it "denies access to user" do
        expect(subject).to_not permit(User.new, repository)
      end

      it "grants access for admin of platform" do
        allow_any_instance_of(RepositoryPolicy).to receive(:local_admin?).
          with(repository.platform).and_return(true)
        expect(subject).to permit(User.new, repository)
      end

      it "grants access for member of repository" do
        user = FactoryGirl.build(:user, id: 123)
        allow_any_instance_of(RepositoryPolicy).to receive(:repository_user_ids).and_return([123])
        expect(subject).to permit(user, repository)
      end

      it "grants access for to global admin" do
        expect(subject).to permit(FactoryGirl.build(:admin), repository)
      end
    end
  end

  permissions :settings? do
    it "denies access to user" do
      expect(subject).to_not permit(User.new, repository)
    end

    it "grants access for admin of platform" do
      allow_any_instance_of(RepositoryPolicy).to receive(:local_admin?).
        with(repository.platform).and_return(true)
      expect(subject).to permit(User.new, repository)
    end

    it "grants access for to global admin" do
      expect(subject).to permit(FactoryGirl.build(:admin), repository)
    end
  end

  permissions :key_pair? do
    it "denies access to user" do
      expect(subject).to_not permit(User.new, repository)
    end

    it "denies access for to global admin" do
      expect(subject).to_not permit(FactoryGirl.build(:admin), repository)
    end

    it "grants access to system user" do
      expect(subject).to permit(FactoryGirl.build(:user, role: 'system'), repository)
    end
  end

  %i(add_repo_lock_file? remove_repo_lock_file?).each do |perm|
    permissions perm do
      it "denies access to user" do
        expect(subject).to_not permit(User.new, repository)
      end

      it "grants access for admin of platform" do
        allow_any_instance_of(RepositoryPolicy).to receive(:local_admin?).
          with(repository.platform).and_return(true)
        expect(subject).to permit(User.new, repository)
      end

      it "denies access for admin of personal platform" do
        allow(repository.platform).to receive(:main?).and_return(false)
        allow_any_instance_of(RepositoryPolicy).to receive(:local_admin?).
          with(repository.platform).and_return(true)
        expect(subject).to_not permit(User.new, repository)
      end

      it "grants access for to global admin" do
        expect(subject).to permit(FactoryGirl.build(:admin), repository)
      end

      it "grants access to system user" do
        expect(subject).to permit(FactoryGirl.build(:user, role: 'system'), repository)
      end
    end
  end

end
