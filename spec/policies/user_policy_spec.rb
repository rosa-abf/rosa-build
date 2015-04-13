require 'spec_helper'

RSpec.describe UserPolicy, type: :policy do
  let(:user)  { FactoryGirl.build(:user) }
  subject { described_class }


  permissions :show? do
    it "grants access to anonymous user" do
      expect(subject).to permit(User.new, user)
    end
  end

  %i(update? notifiers? show_current_user? write?).each do |perm|
    permissions perm do
      it "denies access to user" do
        expect(subject).to_not permit(User.new, user)
      end

      it "grants access for himself" do
        expect(subject).to permit(user, user)
      end

      it "grants access for to global admin" do
        expect(subject).to permit(FactoryGirl.build(:admin), user)
      end
    end
  end

end
