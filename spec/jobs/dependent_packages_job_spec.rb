require 'spec_helper'

describe BuildLists::DependentPackagesJob do
  let(:build_list)  { FactoryGirl.build(:build_list, id: 123) }
  let(:user)        { build_list.user }
  let(:project)     { build_list.project }
  let(:project_ids) { [build_list.project_id] }
  let(:arch_ids)    { [build_list.arch_id] }
  let(:options)     { {
    'auto_publish_status'            => 'none',
    'auto_create_container'          => '0',
    'include_testing_subrepository'  => '0',
    'use_cached_chroot'              => '0',
    'use_extra_tests'                => '0'
  } }

  before do
    stub_symlink_methods
    allow(BuildList).to receive(:find).with(123).and_return(build_list)
    allow(Project).to receive_message_chain(:where, :to_a).and_return([project])
    allow(Arch).to receive_message_chain(:where, :to_a).and_return([build_list.arch])

    allow_any_instance_of(BuildList).to       receive(:update_statistic)
    allow_any_instance_of(BuildListPolicy).to receive(:show?).and_return(true)
    allow_any_instance_of(ProjectPolicy).to   receive(:write?).and_return(true)
    allow_any_instance_of(BuildListPolicy).to receive(:create?).and_return(true)
  end

  subject { BuildLists::DependentPackagesJob }

  it 'ensures that not raises error' do
    expect do
      subject.perform build_list.id, user.id, project_ids, arch_ids, options
    end.to_not raise_exception
  end

  it 'ensures that creates build_list' do
    expect do
      subject.perform build_list.id, user.id, project_ids, arch_ids, options
    end.to change(BuildList, :count).by(1)
  end

  it 'ensures that do nothing if user has no access for show of build_list' do
    allow_any_instance_of(BuildListPolicy).to receive(:show?).and_return(false)
    expect do
      subject.perform build_list.id, user.id, project_ids, arch_ids, options
    end.to change(BuildList, :count).by(0)
  end

  it 'ensures that do nothing if user has no access for write of project' do
    allow_any_instance_of(ProjectPolicy).to receive(:write?).and_return(false)
    expect do
      subject.perform build_list.id, user.id, project_ids, arch_ids, options
    end.to change(BuildList, :count).by(0)
  end

  it 'ensures that do nothing if user has no access for create of build_list' do
    allow_any_instance_of(BuildListPolicy).to receive(:create?).and_return(false)
    expect do
      subject.perform build_list.id, user.id, project_ids, arch_ids, options
    end.to change(BuildList, :count).by(0)
  end

end
