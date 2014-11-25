require 'spec_helper'

describe ProjectStatistic do

  context 'ensures that validations and associations exist' do
    it { should belong_to(:project) }
    it { should belong_to(:arch) }

    it { should validate_presence_of(:project) }
    it { should validate_presence_of(:arch) }
    it { should validate_presence_of(:average_build_time) }
    it { should validate_presence_of(:build_count) }

    it { should_not allow_mass_assignment_of(:project_id) }
    it { should_not allow_mass_assignment_of(:arch_id) }

    it 'uniqueness of project_id and arch_id' do
      FactoryGirl.create(:project_statistic)
      should validate_uniqueness_of(:project_id).scoped_to(:arch_id)
    end

  end

end
