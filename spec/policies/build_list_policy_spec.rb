require 'spec_helper'

RSpec.describe BuildListPolicy, type: :policy do
  let(:build_list) { FactoryGirl.build(:build_list) }
  subject { described_class }

  permissions :index? do
    it "grants access to anonymous user" do
      expect(subject).to permit(User.new, build_list)
    end

    it "grants access to user" do
      expect(subject).to permit(FactoryGirl.create(:user), build_list)
    end
  end

  %i(show? read? log? everything? owned? everything? list?).each do |perm|
    permissions perm do
      it "grants access for creator" do
        expect(subject).to permit(build_list.user, build_list)
      end

      it "grants access if user can read project" do
        allow_any_instance_of(ProjectPolicy).to receive(:show?).and_return(true)
        expect(subject).to permit(User.new, build_list)
      end

      it "denies access if user can not read project" do
        allow_any_instance_of(ProjectPolicy).to receive(:show?).and_return(false)
        expect(subject).to_not permit(User.new, build_list)
      end
    end
  end

  %i(create? rerun_tests?).each do |perm|
    permissions perm do
      before do
        allow_any_instance_of(ProjectPolicy).to receive(:write?).and_return(true)
        allow_any_instance_of(PlatformPolicy).to receive(:show?).and_return(true)
      end

      it "grants access to user" do
        expect(subject).to permit(FactoryGirl.build(:user), build_list)
      end

      it "denies access if project is not a package" do
        build_list.project.is_package = false
        expect(subject).to_not permit(User.new, build_list)
      end

      it "denies access if user can not write to project" do
        allow_any_instance_of(ProjectPolicy).to receive(:write?).and_return(false)
        expect(subject).to_not permit(User.new, build_list)
      end

      it "denies access if user can not read platform" do
        allow_any_instance_of(PlatformPolicy).to receive(:show?).and_return(false)
        expect(subject).to_not permit(User.new, build_list)
      end
    end
  end

  permissions :dependent_projects? do
    before do
      allow_any_instance_of(BuildListPolicy).to receive(:create?).and_return(true)
    end

    it "grants access to user" do
      expect(subject).to permit(User.new, build_list)
    end

    it "denies access if user can not to create build list" do
      allow_any_instance_of(BuildListPolicy).to receive(:create?).and_return(false)
      expect(subject).to_not permit(User.new, build_list)
    end

    it "denies access if save_to_platform is not main" do
      allow(build_list.save_to_platform).to receive(:main?).and_return(false)
      expect(subject).to_not permit(User.new, build_list)
    end
  end

  permissions :publish_into_testing? do
    before do
      allow_any_instance_of(BuildListPolicy).to receive(:create?).and_return(true)
      allow_any_instance_of(BuildListPolicy).to receive(:publish?).and_return(true)
      allow(build_list).to receive(:can_publish_into_testing?).and_return(true)
    end

    it "grants access to user" do
      expect(subject).to permit(User.new, build_list)
    end

    it "grants access if user can not to create but can publish build list" do
      allow_any_instance_of(BuildListPolicy).to receive(:create?).and_return(false)
      expect(subject).to permit(User.new, build_list)
    end

    it "denies access if build is from old core" do
      build_list.new_core = false
      expect(subject).to_not permit(User.new, build_list)
    end

    it "denies access if build can not be published" do
      allow(build_list).to receive(:can_publish_into_testing?).and_return(false)
      expect(subject).to_not permit(User.new, build_list)
    end

    it "denies access if user can not to create and publish build list" do
      allow_any_instance_of(BuildListPolicy).to receive(:create?).and_return(false)
      allow_any_instance_of(BuildListPolicy).to receive(:publish?).and_return(false)
      expect(subject).to_not permit(User.new, build_list)
    end

    context 'for personal platform' do
      before do
        allow(build_list.save_to_platform).to receive(:main?).and_return(false)
      end

      it "grants access to user" do
        expect(subject).to permit(User.new, build_list)
      end

      it "denies access if user can not to create but can publish build list" do
        allow_any_instance_of(BuildListPolicy).to receive(:create?).and_return(false)
        expect(subject).to_not permit(User.new, build_list)
      end
    end
  end

  permissions :publish? do
    before do
      allow(build_list).to receive(:can_publish?).and_return(true)
    end

    context 'build published' do
      before do
        allow(build_list).to receive(:build_published?).and_return(true)
      end

      it "denies access to user" do
        expect(subject).to_not permit(User.new, build_list)
      end

      it "grants access to admin of platform" do
        allow_any_instance_of(BuildListPolicy).to receive(:local_admin?).
          with(build_list.save_to_platform).and_return(true)
        expect(subject).to permit(User.new, build_list)
      end

      it "grants access to member of repository" do
        allow(build_list.save_to_repository).to receive_message_chain(:members, :exists?).and_return(true)
        expect(subject).to permit(User.new, build_list)
      end
    end

    context 'build not published' do
      it "denies access to user" do
        expect(subject).to_not permit(User.new, build_list)
      end

      it "grants access to admin of platform if publish_without_qa is disabled" do
        build_list.save_to_repository.publish_without_qa = false
        allow_any_instance_of(BuildListPolicy).to receive(:local_admin?).
          with(build_list.save_to_platform).and_return(true)

        expect(subject).to permit(User.new, build_list)
      end

      it "grants access if user can write to project" do
        allow_any_instance_of(ProjectPolicy).to receive(:write?).and_return(true)
        expect(subject).to permit(User.new, build_list)
      end
    end
  end

  permissions :create_container? do
    it "denies access to user" do
      expect(subject).to_not permit(User.new, build_list)
    end

    context 'user can write to project' do
      before do
        allow_any_instance_of(ProjectPolicy).to receive(:write?).and_return(true)
      end

      it "grants access to user" do
        expect(subject).to permit(User.new, build_list)
      end

      it "denies access if build is from old core" do
        build_list.new_core = false
        expect(subject).to_not permit(User.new, build_list)
      end
    end

    context 'user admin of platform' do
      before do
        allow_any_instance_of(BuildListPolicy).to receive(:local_admin?).
          with(build_list.save_to_platform).and_return(true)
      end

      it "grants access to user" do
        expect(subject).to permit(User.new, build_list)
      end

      it "denies access if build is from old core" do
        build_list.new_core = false
        expect(subject).to_not permit(User.new, build_list)
      end
    end
  end

  permissions :reject_publish? do
    it "denies access to user" do
      expect(subject).to_not permit(User.new, build_list)
    end

    it "grants access if user can write to project" do
      allow_any_instance_of(ProjectPolicy).to receive(:write?).and_return(true)
      expect(subject).to permit(User.new, build_list)
    end

    it "denies access to admin of platform" do
      allow_any_instance_of(BuildListPolicy).to receive(:local_admin?).
        with(build_list.save_to_platform).and_return(true)
      expect(subject).to_not permit(User.new, build_list)
    end

    context 'publish_without_qa is disabled' do
      before do
        build_list.save_to_repository.publish_without_qa = false
      end

      it "denies access to user" do
        expect(subject).to_not permit(User.new, build_list)
      end

      it "denies access if user can write to project" do
        allow_any_instance_of(ProjectPolicy).to receive(:write?).and_return(true)
        expect(subject).to_not permit(User.new, build_list)
      end

      it "grants access to admin of platform" do
        allow_any_instance_of(BuildListPolicy).to receive(:local_admin?).
          with(build_list.save_to_platform).and_return(true)
        expect(subject).to permit(User.new, build_list)
      end
    end
  end

  permissions :cancel? do
    it "denies access to user" do
      expect(subject).to_not permit(User.new, build_list)
    end

    it "grants access if user can write to project" do
      allow_any_instance_of(ProjectPolicy).to receive(:write?).and_return(true)
      expect(subject).to permit(User.new, build_list)
    end
  end

end
