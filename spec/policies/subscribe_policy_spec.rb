require 'spec_helper'

RSpec.describe SubscribePolicy, type: :policy do
  let(:subscribe) { FactoryGirl.create(:subscribe) }
  subject { described_class }

  permissions :create? do
    it "denies access to anonymous user" do
      expect(subject).to_not permit(User.new, subscribe)
    end

    it "grants access to user" do
      expect(subject).to permit(FactoryGirl.create(:user), subscribe)
    end

    it "denies access if user already subscribed" do
      expect(subject).to_not permit(subscribe.user, subscribe)
    end
  end

  permissions :destroy? do
    it "denies access to anonymous user" do
      expect(subject).to_not permit(User.new, subscribe)
    end

    it "denies access to user" do
      expect(subject).to_not permit(FactoryGirl.create(:user), subscribe)
    end

    it "grants access if user already subscribed" do
      expect(subject).to permit(subscribe.user, subscribe)
    end
  end

end
