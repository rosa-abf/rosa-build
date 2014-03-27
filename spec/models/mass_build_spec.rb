require 'spec_helper'

describe MassBuild do
  before { stub_symlink_methods }

  context 'ensures that validations and associations exist' do

    it 'is valid given valid attributes' do
      FactoryGirl.create(:mass_build).should be_true
    end

    it { should belong_to(:build_for_platform) }
    it { should belong_to(:save_to_platform) }
    it { should belong_to(:user) }
    it { should have_many(:build_lists)}

    it { should validate_presence_of(:save_to_platform_id)}
    it { should validate_presence_of(:build_for_platform_id)}
    it { should validate_presence_of(:user_id)}
    it { should validate_presence_of(:arch_names)}
    it { should validate_presence_of(:name)}

    it { should validate_presence_of(:projects_list)}
    it { should ensure_length_of(:projects_list).is_at_most(500_000) }


    it { should_not allow_mass_assignment_of(:name) }
    it { should_not allow_mass_assignment_of(:arch_names) }
  end

  it 'ensures that projects_list contains unique projects' do
    projects_list = %(at
      at
      ab
    )
    mass_build = FactoryGirl.create(:mass_build, projects_list: projects_list)
    list = mass_build.projects_list.split(/[\r]*\n/)
    list.should have(2).items
    list.should include('at', 'ab')
  end
end
