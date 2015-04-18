require 'spec_helper'

RSpec.describe ProjectPolicy, type: :policy do
  let(:project) { FactoryGirl.build(:project) }
  let(:user)  { FactoryGirl.create(:user) }
  subject { described_class }


  permissions :index? do
    it "denies access to anonymous user" do
      expect(subject).to_not permit(User.new, :project)
    end

    it "grants access to user" do
      expect(subject).to permit(user, :project)
    end
  end

  %i(show? read? archive? get_id? refs_list?).each do |perm|
    permissions perm do
      it "grants access to anonymous user" do
        expect(subject).to permit(User.new, project)
      end

      context 'hidden project' do
        before do
          project.visibility = 'hidden'
        end

        it "denies access to anonymous user" do
          expect(subject).to_not permit(User.new, project)
        end

        it "grants access for owner of project" do
          expect(subject).to permit(project.owner, project)
        end

        it "grants access for member of project owner group" do
          project = FactoryGirl.build(:group_project)
          allow_any_instance_of(ProjectPolicy).to receive(:user_group_ids).and_return([project.owner_id])
          expect(subject).to permit(User.new, project)
        end

        it "grants access for reader of project" do
          allow_any_instance_of(ProjectPolicy).to receive(:local_reader?).and_return(true)
          expect(subject).to permit(User.new, project)
        end

        it "grants access for to global admin" do
          expect(subject).to permit(FactoryGirl.build(:admin), project)
        end
      end
    end
  end

  permissions :fork? do
    it "denies access to anonymous user" do
      expect(subject).to_not permit(User.new, project)
    end

    it "grants access to user" do
      expect(subject).to permit(user, project)
    end

    context 'hidden project' do
      before do
        project.visibility = 'hidden'
      end

      it "grants access for owner of project" do
        expect(subject).to permit(project.owner, project)
      end

      it "grants access for member of project owner group" do
        project = FactoryGirl.build(:group_project)
        allow_any_instance_of(ProjectPolicy).to receive(:user_group_ids).and_return([project.owner_id])
        expect(subject).to permit(user, project)
      end

      it "grants access for reader of project" do
        allow_any_instance_of(ProjectPolicy).to receive(:local_reader?).and_return(true)
        expect(subject).to permit(user, project)
      end

      it "grants access for to global admin" do
        expect(subject).to permit(FactoryGirl.create(:admin), project)
      end
    end
  end

  permissions :create? do
    it "denies access to anonymous user" do
      expect(subject).to_not permit(User.new, project)
    end

    it "denies access if user can not write to owner" do
      allow_any_instance_of(UserPolicy).to receive(:write?).and_return(false)
      expect(subject).to_not permit(user, project)
    end

    it "grants access if user can write to owner" do
      allow_any_instance_of(UserPolicy).to receive(:write?).and_return(true)
      expect(subject).to permit(user, project)
    end

    it "grants access for to global admin" do
      expect(subject).to permit(FactoryGirl.create(:admin), project)
    end
  end

  %i(
    add_member?
    alias?
    autocomplete_maintainers?
    manage_collaborators?
    members?
    remove_member?
    remove_members?
    schedule?
    sections?
    update?
    update_member?
  ).each do |perm|
    permissions perm do
      it "denies access to anonymous user" do
        expect(subject).to_not permit(User.new, project)
      end

      it "denies access to user" do
        expect(subject).to_not permit(user, project)
      end

      it "grants access for owner of project" do
        expect(subject).to permit(project.owner, project)
      end

      it "grants access for admin of project" do
        allow_any_instance_of(ProjectPolicy).to receive(:local_admin?).and_return(true)
        expect(subject).to permit(user, project)
      end

      it "grants access for to global admin" do
        expect(subject).to permit(FactoryGirl.create(:admin), project)
      end
    end
  end

  permissions :destroy? do
    it "denies access to anonymous user" do
      expect(subject).to_not permit(User.new, project)
    end

    it "denies access to user" do
      expect(subject).to_not permit(user, project)
    end

    it "grants access for owner of project" do
      expect(subject).to permit(project.owner, project)
    end

    it "grants access for to global admin" do
      expect(subject).to permit(FactoryGirl.create(:admin), project)
    end

    context 'owner is group' do
      let(:project) { FactoryGirl.create(:group_project) }
      before do
        project.owner.add_member user, 'admin'
      end

      it "grants access for admin of project owner group" do
        expect(subject).to permit(user, project)
      end
    end
  end

  permissions :mass_import? do
    it "denies access to anonymous user" do
      expect(subject).to_not permit(User.new, project)
    end

    it "denies access to user" do
      expect(subject).to_not permit(user, project)
    end

    it "grants access for admin of main platform" do
      platform = FactoryGirl.create(:platform)
      platform.add_member user, 'admin'
      expect(subject).to permit(user, project)
    end

    it "grants access for to global admin" do
      expect(subject).to permit(FactoryGirl.create(:admin), project)
    end
  end

  permissions :run_mass_import? do
    let(:repository) { FactoryGirl.create(:repository) }
    before do
      project.add_to_repository_id = repository.id
    end

    it "denies access to anonymous user" do
      expect(subject).to_not permit(User.new, project)
    end

    it "denies access to user" do
      expect(subject).to_not permit(user, project)
    end

    context 'user can add projects to platform and can write to owner' do
      before do
        allow_any_instance_of(UserPolicy).to receive(:write?).and_return(true)
        allow_any_instance_of(PlatformPolicy).to receive(:add_project?).and_return(true)
      end

      it "grants access to user" do
        expect(subject).to permit(user, project)
      end

      it "denies access to user for personal platform" do
        allow_any_instance_of(Platform).to receive(:main?).and_return(false)
        expect(subject).to_not permit(user, project)
      end
    end

    it "grants access for to global admin" do
      expect(subject).to permit(FactoryGirl.create(:admin), project)
    end
  end

  permissions :write? do
    it "denies access to anonymous user" do
      expect(subject).to_not permit(User.new, project)
    end

    it "denies access to user" do
      expect(subject).to_not permit(user, project)
    end

    it "grants access for owner of project" do
      expect(subject).to permit(project.owner, project)
    end

    it "grants access for writer of project" do
      allow_any_instance_of(ProjectPolicy).to receive(:local_writer?).and_return(true)
      expect(subject).to permit(user, project)
    end

    it "grants access for to global admin" do
      expect(subject).to permit(FactoryGirl.create(:admin), project)
    end
  end

end
