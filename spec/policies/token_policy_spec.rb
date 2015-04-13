require 'spec_helper'

RSpec.describe TokenPolicy, type: :policy do
  let(:token) { FactoryGirl.build(:platform_token) }
  subject { described_class }

  %i(show? create? read? withdraw?).each do |perm|
    permissions perm do
      it "denies access to user" do
        expect(subject).to_not permit(User.new, token)
      end

      it "grants access to owner of platform" do
        allow_any_instance_of(TokenPolicy).to receive(:owner?).and_return(true)
        expect(subject).to permit(User.new, token)
      end

      it "grants access to admin of platform" do
        allow_any_instance_of(TokenPolicy).to receive(:local_admin?).and_return(true)
        expect(subject).to permit(User.new, token)
      end

      it "grants access for to global admin" do
        expect(subject).to permit(FactoryGirl.build(:admin), token)
      end
    end
  end

end
