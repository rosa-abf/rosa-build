require 'spec_helper'

RSpec.describe AdvisoryPolicy, type: :policy do
  let(:advisory) { FactoryGirl.build(:advisory) }
  subject { described_class }

  %i(index? search? show?).each do |perm|
    permissions perm do
      it "grants access to anonymous user" do
        expect(subject).to permit(User.new, advisory)
      end

      it "grants access to user" do
        expect(subject).to permit(FactoryGirl.create(:user), advisory)
      end
    end
  end

  %i(create? update?).each do |perm|
    permissions perm do
      it "denies access to anonymous user" do
        expect(subject).not_to permit(User.new, advisory)
      end

      it "grants access to user" do
        expect(subject).to permit(FactoryGirl.create(:user), advisory)
      end
    end
  end

end
