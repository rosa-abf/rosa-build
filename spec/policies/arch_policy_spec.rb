require 'spec_helper'

RSpec.describe ArchPolicy, type: :policy do
  let(:arch) { FactoryGirl.build(:arch) }
  subject { described_class }

  permissions :index? do
    it "grants access to anonymous user" do
      expect(subject).to permit(User.new, arch)
    end

    it "grants access to user" do
      expect(subject).to permit(FactoryGirl.create(:user), arch)
    end
  end

end
