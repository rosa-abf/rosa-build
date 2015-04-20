require 'spec_helper'

RSpec.describe MassBuildPolicy, type: :policy do
  let(:mass_build) { FactoryGirl.build(:mass_build) }
  subject { described_class }

  %i(show? read? get_list?).each do |perm|
    permissions perm do
      it "denies access if user can not show a platform" do
        allow_any_instance_of(PlatformPolicy).to receive(:show?).and_return(false)
        expect(subject).to_not permit(User.new, mass_build)
      end

      it "grants access if user can show a platform" do
        allow_any_instance_of(PlatformPolicy).to receive(:show?).and_return(true)
        expect(subject).to permit(User.new, mass_build)
      end

      it "grants access for to global admin" do
        expect(subject).to permit(FactoryGirl.build(:admin), mass_build)
      end
    end
  end

  %i(create? publish?).each do |perm|
    permissions perm do
      it "denies access to user" do
        expect(subject).to_not permit(User.new, mass_build)
      end

      it "grants access for admin of platform" do
        allow_any_instance_of(MassBuildPolicy).to receive(:local_admin?).
          with(mass_build.save_to_platform).and_return(true)
        expect(subject).to permit(User.new, mass_build)
      end

      it "grants access for owner of platform" do
        allow_any_instance_of(MassBuildPolicy).to receive(:owner?).
          with(mass_build.save_to_platform).and_return(true)
        expect(subject).to permit(User.new, mass_build)
      end

      it "grants access for to global admin" do
        expect(subject).to permit(FactoryGirl.build(:admin), mass_build)
      end
    end
  end

  permissions :cancel? do
    before do
      mass_build.stop_build = false
    end

    it "denies access to user" do
      expect(subject).to_not permit(User.new, mass_build)
    end

    context 'user can create mass build' do
      before do
        allow_any_instance_of(MassBuildPolicy).to receive(:create?).and_return(true)
      end

      it "grants access to user" do
        expect(subject).to permit(User.new, mass_build)
      end

      it "denies access to user if mass build has been stopped" do
        mass_build.stop_build = true
        expect(subject).to_not permit(User.new, mass_build)
      end
    end
  end

end
