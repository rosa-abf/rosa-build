require 'spec_helper'

describe RestartNodesJob do

  it 'ensures that not raises error' do
    lambda do
      RestartNodesJob.perform
    end.should_not raise_exception
  end

  it 'ensures that do nothing when all instructions disabled' do
    NodeInstruction.lock_all
    expect(RpmBuildNode).to_not receive(:all)
    RestartNodesJob.perform
  end

  it 'ensures that creates tasks' do
    allow_any_instance_of(NodeInstruction).to receive(:perform_restart)

    # ABF active node
    ni1 = FactoryGirl.create(:node_instruction)
    FactoryGirl.create(:rpm_build_node, user_id: ni1.user_id)

    # User node
    FactoryGirl.create(:rpm_build_node)

    FactoryGirl.create(:node_instruction, status: NodeInstruction::DISABLED)
    ni2 = FactoryGirl.create(:node_instruction, status: NodeInstruction::RESTARTING)
    FactoryGirl.create(:node_instruction, status: NodeInstruction::FAILED)

    ni3 = FactoryGirl.create(:node_instruction)

    RestartNodesJob.perform

    expect(NodeInstruction.where(status: NodeInstruction::RESTARTING).count).to eq 2
    NodeInstruction.where(status: NodeInstruction::RESTARTING).should include(ni2, ni3)
    NodeInstruction.where(status: NodeInstruction::RESTARTING).should_not include(ni1)
  end

end
