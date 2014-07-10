require 'spec_helper'

describe RunExtraMassBuildsJob do
  let(:mass_build1) { FactoryGirl.build(:mass_build, id: 123) }
  let(:mass_build2) { FactoryGirl.build(:mass_build, id: 234, extra_mass_builds: [mass_build1.id]) }
  let(:build_list)  { FactoryGirl.build(:build_list, id: 345, mass_build: mass_build) }

  let(:job)         { RunExtraMassBuildsJob.new }

  before do
    stub_symlink_methods
    MassBuild.stub_chain(:where, :find_each).and_yield(mass_build2)
    MassBuild.stub_chain(:where, :to_a).and_return([mass_build1])
    allow(job).to receive(:not_ready?).with(mass_build1).and_return(false)
    allow(mass_build2).to receive(:build_all)
  end

  it 'ensures that not raises error' do
    expect do
      job.perform
    end.to_not raise_exception
  end

  it 'ensures that calls #build_all' do
    expect(mass_build2).to receive(:build_all)
    job.perform
  end

  it 'ensures that do nothing when no extra_mass_builds' do
    mass_build2.extra_mass_builds = []
    expect(mass_build2).to_not receive(:build_all)
    job.perform
  end

  it 'ensures that do nothing when extra mass build not ready' do
    allow(job).to receive(:not_ready?).with(mass_build1).and_return(true)
    expect(mass_build2).to_not receive(:build_all)
    job.perform
  end

  it 'ensures that do nothing when some extra mass builds have no status SUCCESS' do
    mass_build0 = FactoryGirl.build(:mass_build, id: 1)
    mass_build2.extra_mass_builds = [mass_build0, mass_build1]
    MassBuild.stub_chain(:where, :to_a).and_return([mass_build1])
    expect(mass_build2).to_not receive(:build_all)
    job.perform
  end

end
