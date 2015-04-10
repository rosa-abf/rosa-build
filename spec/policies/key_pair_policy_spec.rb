require 'spec_helper'

RSpec.describe KeyPairPolicy, type: :policy do
  let(:key_pair) { FactoryGirl.build(:key_pair) }
  subject { described_class }

  %i(create? destroy?).each do |perm|
    permissions perm do
      it "denies access to user" do
        expect(subject).to_not permit(User.new, key_pair)
      end

      it "grants access for admin of platform" do
        allow_any_instance_of(KeyPairPolicy).to receive(:local_admin?).
          with(key_pair.repository.platform).and_return(true)
        expect(subject).to permit(User.new, key_pair)
      end

      it "grants access for to global admin" do
        expect(subject).to permit(FactoryGirl.build(:admin), key_pair)
      end
    end
  end

end
