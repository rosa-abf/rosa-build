# -*- encoding : utf-8 -*-
require 'spec_helper'

describe Project do
  before(:each) do
    stub_symlink_methods
    @root_project = FactoryGirl.create(:project)
    @child_project = @root_project.fork(FactoryGirl.create(:user))
    @child_child_project = @child_project.fork(FactoryGirl.create(:user))
  end

  context 'for destroy root' do
    before(:each) do
      @root_project.destroy
    end

    it "should not be delete child" do
      Project.where(:id => @child_project).count.should == 1
    end

    it "should not be delete child of the child" do
      Project.where(:id => @child_child_project).count.should == 1
    end
  end

  # uncommit when will be available :orphan_strategy => :adopt

  #context 'for destroy middle node' do
  #  before(:each) do
  #    @child_project.destroy
  #  end

  #  it "should set root project as a parent for orphan child" do
  #    Project.find(@child_child_project).ancestry == @root_project
  #  end

  #  it "should not be delete child of the child" do
  #    Project.where(:id => @child_child_project).count.should == 1
  #  end
  #end
end