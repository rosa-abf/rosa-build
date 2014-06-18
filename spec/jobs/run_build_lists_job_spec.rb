require 'spec_helper'

describe BuildLists::DependentPackagesJob do
  let(:build_list)  { FactoryGirl.build(:build_list, id: 123) }
  let(:user)        { build_list.user }
  let(:project)     { build_list.project }
  let(:ability)     { double(:ability) }

  before do
    stub_symlink_methods
    allow(BuildList).to receive(:find).with(123).and_return(build_list)
    BuildList::Package.stub_chain(:joins, :where, :reorder, :uniq, :pluck).and_return([project.id])
    Project.stub_chain(:where, :to_a).and_return([project])

    allow(Ability).to receive(:new).and_return(ability)
    allow(ability).to receive(:can?).with(:show, build_list).and_return(true)
    allow(ability).to receive(:can?).with(:write, project).and_return(true)
    allow(ability).to receive(:can?).with(:create, anything).and_return(true)
  end

  subject { BuildLists::DependentPackagesJob }

  it 'ensures that not raises error' do
    expect do
      subject.perform build_list.id, user.id
    end.to_not raise_exception
  end

  it 'ensures that creates build_list' do
    expect do
      subject.perform build_list.id, user.id
    end.to change(BuildList, :count).by(1)
  end

  it 'ensures that do nothing if user has no access for show of build_list' do
    allow(ability).to receive(:can?).with(:show, build_list).and_return(false)
    expect do
      subject.perform build_list.id, user.id
    end.to change(BuildList, :count).by(0)
  end

  it 'ensures that do nothing if user has no access for write of project' do
    allow(ability).to receive(:can?).with(:write, project).and_return(false)
    expect do
      subject.perform build_list.id, user.id
    end.to change(BuildList, :count).by(0)
  end

  it 'ensures that do nothing if user has no access for create of build_list' do
    allow(ability).to receive(:can?).with(:create, anything).and_return(false)
    expect do
      subject.perform build_list.id, user.id
    end.to change(BuildList, :count).by(0)
  end

end
