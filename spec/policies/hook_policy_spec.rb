require 'spec_helper'

RSpec.describe HookPolicy, type: :policy do
  let(:hook) { FactoryGirl.build(:hook) }
  subject { described_class }

  %i(show? read? create? destroy? update?).each do |perm|
    permissions perm do
      it "denies access to anonymous user" do
        expect(subject).to_not permit(User.new, hook)
      end

      it "denies access if user can not update a project" do
        allow_any_instance_of(ProjectPolicy).to receive(:update?).and_return(false)
        expect(subject).to_not permit(User.new, hook)
      end

      it "grants access if user can update a project" do
        allow_any_instance_of(ProjectPolicy).to receive(:update?).and_return(true)
        expect(subject).to permit(User.new, hook)
      end
    end
  end

end
