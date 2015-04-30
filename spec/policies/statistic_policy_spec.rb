require 'spec_helper'

RSpec.describe StatisticPolicy, type: :policy do
  subject { described_class }

  permissions :index? do
    it "grants access to user" do
      expect(subject).to permit(User.new, :statistic)
    end
  end

end
