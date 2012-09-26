# -*- encoding : utf-8 -*-
require 'spec_helper'

describe Project do
  before do
    stub_symlink_methods
    @root_project = FactoryGirl.create(:project)
    @child_project = @root_project.fork(FactoryGirl.create(:user))
    @child_child_project = @child_project.fork(FactoryGirl.create(:user))
  end

  context 'for destroy root' do
    before do
      @root_project.destroy
    end

    it "should not be delete child" do
      Project.where(:id => @child_project).count.should == 1
    end

    it "should not be delete child of the child" do
      Project.where(:id => @child_child_project).count.should == 1
    end
  end

  context 'attach personal repository' do
    let(:user) { FactoryGirl.create(:user) }
    it "ensures that personal repository has been attached when project had been created as package" do
      project = FactoryGirl.create(:project, :owner => user, :is_package => true)
      project.repositories.should == [user.personal_repository]
    end

    it "ensures that personal repository has not been attached when project had been created as not package" do
      project = FactoryGirl.create(:project, :owner => user, :is_package => false)
      project.repositories.should have(:no).items
    end

    it "ensures that personal repository has been attached when project had been updated as package" do
      project = FactoryGirl.create(:project, :owner => user, :is_package => false)
      project.update_attribute(:is_package, true)
      project.repositories.should == [user.personal_repository]
    end

    it "ensures that personal repository has been removed from project when project had been updated as not package" do
      project = FactoryGirl.create(:project, :owner => user, :is_package => true)
      project.update_attribute(:is_package, false)
      project.repositories.should have(:no).items
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
