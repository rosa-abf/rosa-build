require 'spec_helper'

RSpec.describe ProductPolicy, type: :policy do
  let(:product) { FactoryGirl.build(:product) }
  subject { described_class }

  permissions :index? do
    it "grants access to user" do
      expect(subject).to permit(User.new, product)
    end

    context 'personal platform' do
      let(:platform) { FactoryGirl.build(:personal_platform) }
      before do
        product.platform = platform
      end

      it "denies access to user" do
        expect(subject).to_not permit(User.new, product)
      end
    end
  end

  %i(show? read?).each do |perm|
    permissions perm do
      it "denies access to user if user can not show a platform" do
        allow_any_instance_of(PlatformPolicy).to receive(:show?).and_return(false)
        expect(subject).not_to permit(User.new, product)
      end

      it "grants access if user can show a platform" do
        allow_any_instance_of(PlatformPolicy).to receive(:show?).and_return(true)
        expect(subject).to permit(User.new, product)
      end

      it "grants access for to global admin" do
        expect(subject).to permit(FactoryGirl.build(:admin), product)
      end
    end
  end

  %i(create? clone? destroy? update?).each do |perm|
    permissions perm do
      it "denies access to user" do
        expect(subject).not_to permit(User.new, product)
      end

      it "grants access for admin of platform" do
        allow_any_instance_of(ProductPolicy).to receive(:local_admin?).
          with(product.platform).and_return(true)
        expect(subject).to permit(User.new, product)
      end

      it "grants access for owner of platform" do
        allow_any_instance_of(ProductPolicy).to receive(:owner?).
          with(product.platform).and_return(true)
        expect(subject).to permit(User.new, product)
      end

      it "grants access for to global admin" do
        expect(subject).to permit(FactoryGirl.build(:admin), product)
      end

      context 'personal platform' do
        let(:platform) { FactoryGirl.build(:personal_platform) }
        before do
          product.platform = platform
        end

        it "denies access for admin of platform" do
          allow_any_instance_of(ProductPolicy).to receive(:local_admin?).
            with(product.platform).and_return(true)
          expect(subject).not_to permit(User.new, product)
        end

        it "denies access for owner of platform" do
          allow_any_instance_of(ProductPolicy).to receive(:owner?).
            with(product.platform).and_return(true)
          expect(subject).not_to permit(User.new, product)
        end
      end
    end
  end

end
