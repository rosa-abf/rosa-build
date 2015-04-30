require 'spec_helper'

RSpec.describe ProductBuildListPolicy, type: :policy do
  let(:pbl) { FactoryGirl.build(:product_build_list) }
  subject { described_class }

  permissions :index? do
    it "grants access to anonymous user" do
      expect(subject).to permit(User.new, pbl)
    end
  end

  %i(show? log? read?).each do |perm|
    permissions perm do
      it "denies access to user if user can not show a product" do
        allow_any_instance_of(ProductPolicy).to receive(:show?).and_return(false)
        expect(subject).not_to permit(User.new, pbl)
      end

      it "grants access if user can show a product" do
        allow_any_instance_of(ProductPolicy).to receive(:show?).and_return(true)
        expect(subject).to permit(User.new, pbl)
      end

      it "grants access for to global admin" do
        expect(subject).to permit(FactoryGirl.build(:admin), pbl)
      end
    end
  end

  %i(create? cancel?).each do |perm|
    permissions perm do
      it "denies access to user" do
        expect(subject).not_to permit(User.new, pbl)
      end

      it "grants access if user can write to project" do
        allow_any_instance_of(ProjectPolicy).to receive(:write?).and_return(true)
        expect(subject).to permit(User.new, pbl)
      end

      it "grants access if user can update a product" do
        allow_any_instance_of(ProductPolicy).to receive(:update?).and_return(true)
        expect(subject).to permit(User.new, pbl)
      end

      it "grants access for to global admin" do
        expect(subject).to permit(FactoryGirl.build(:admin), pbl)
      end
    end
  end

  permissions :update? do
    it "denies access to user" do
      expect(subject).not_to permit(User.new, pbl)
    end

    it "grants access if user can update a product" do
      allow_any_instance_of(ProductPolicy).to receive(:update?).and_return(true)
      expect(subject).to permit(User.new, pbl)
    end

    it "grants access for to global admin" do
      expect(subject).to permit(FactoryGirl.build(:admin), pbl)
    end
  end

  permissions :destroy? do
    it "denies access to user" do
      expect(subject).not_to permit(User.new, pbl)
    end

    it "grants access if user can destroy a product" do
      allow_any_instance_of(ProductPolicy).to receive(:destroy?).and_return(true)
      expect(subject).to permit(User.new, pbl)
    end

    it "grants access for to global admin" do
      expect(subject).to permit(FactoryGirl.build(:admin), pbl)
    end
  end

end
