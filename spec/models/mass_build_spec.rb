require 'spec_helper'

describe MassBuild do
  before { stub_symlink_methods }

  context 'ensures that validations and associations exist' do
    let(:mass_build) { FactoryGirl.build(:mass_build) }

    it 'is valid given valid attributes' do
      expect(mass_build).to be_valid
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
    it { should validate_length_of(:projects_list).is_at_most(500_000) }

    it { should validate_length_of(:description).is_at_most(255) }

  end

  it 'ensures that projects_list contains unique projects' do
    projects_list = %(at
      at
      ab
    )
    mass_build = FactoryGirl.build(:mass_build, projects_list: projects_list)
    expect(mass_build).to be_valid
    list = mass_build.projects_list.split(/[\r]*\n/)
    expect(list.count).to eq 2
    expect(list).to include('at', 'ab')
  end

  it '#generate_list' do
    mb = FactoryGirl.build(:mass_build)
    bl = double(:build_list)

    allow(BuildList).to receive_message_chain(:select, :where, :joins, :find_each).and_yield(bl)
    expect(bl).to receive(:id)
    expect(bl).to receive(:project_name)
    expect(bl).to receive(:arch_name)
    mb.send(:generate_list, 0)
  end

  it '#publish' do
    mb = FactoryGirl.build(:mass_build)
    user = double(:user, id: 123)

    bl1 = double(:build_list, can_publish?: true, has_new_packages?: true)
    bl2 = double(:build_list, can_publish?: true, has_new_packages?: false)
    bl3 = double(:build_list, can_publish?: false, has_new_packages?: true)
    bl4 = double(:build_list, can_publish?: false, has_new_packages?: false)

    finder = double(:finder)
    allow(mb).to receive(:build_lists).and_return(finder)
    allow(finder).to receive(:where).and_return(finder)
    allow(finder).to receive(:find_each).and_yield(bl1).and_yield(bl2).and_yield(bl3).and_yield(bl4)

    expect(finder).to receive(:update_all).with(publisher_id: user.id)
    expect(bl1).to receive(:now_publish)
    expect(bl2).to_not receive(:now_publish)
    expect(bl3).to_not receive(:now_publish)
    expect(bl4).to_not receive(:now_publish)

    mb.send(:publish, user, [])
  end

  it 'ensures that calls #build_all on create' do
    mass_build = FactoryGirl.build(:mass_build)
    expect(mass_build).to receive(:build_all)
    mass_build.save
  end

  it 'ensures that does not call #build_all on create if attached extra mass builds' do
    mass_build = FactoryGirl.build(:mass_build, extra_mass_builds: [1])
    expect(mass_build).to_not receive(:build_all)
    mass_build.save
  end

  context '#build_all' do
    let(:mass_build) { FactoryGirl.create(:mass_build, extra_mass_builds: [1]) }

    it 'ensures that do nothing when build has status build_started' do
      mass_build.start
      expect(mass_build).to_not receive(:projects_list)
      mass_build.build_all
    end

    it 'ensures that works when build has status build_pending' do
      expect(mass_build).to receive(:projects_list).at_least(:once)
      mass_build.build_all
    end
  end

end
