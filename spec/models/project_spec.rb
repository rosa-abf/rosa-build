require 'spec_helper'

describe Project do
  before do
    stub_symlink_methods
    @root_project = FactoryGirl.create(:project)
    @child_project = @root_project.fork(FactoryGirl.create(:user))
    @child_child_project = @child_project.fork(FactoryGirl.create(:user))
  end

  context 'for destroy' do
    let!(:root_project) { FactoryGirl.create(:project) }
    let!(:child_project) { root_project.fork(FactoryGirl.create(:user)) }
    let!(:child_child_project) { child_project.fork(FactoryGirl.create(:user)) }

    context 'root project' do
      before { root_project.destroy }

      it "should not be delete child" do
        Project.where(:id => child_project).count.should == 1
      end

      it "should not be delete child of the child" do
        Project.where(:id => child_child_project).count.should == 1
      end
    end

    pending 'when will be available :orphan_strategy => :adopt' do
      context 'middle node' do
        before{ child_project.destroy }

        it "should set root project as a parent for orphan child" do
          Project.find(child_child_project).ancestry == root_project
        end

        it "should not be delete child of the child" do
          Project.where(:id => child_child_project).count.should == 1
        end
      end
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

  context 'truncates project name before validation' do
    let!(:project) { FactoryGirl.build(:project, :name => '  test_name  ') }

    it 'ensures that validation passed' do
      project.valid?.should be_true
    end

    it 'ensures that name has been truncated' do
      project.valid?
      project.name.should == 'test_name'
    end
  end

  context 'Validate project name' do
    let!(:project) { FactoryGirl.build(:project, :name => '  test_name  ') }

    it "'hacked' uname should not pass" do
      lambda {FactoryGirl.create(:project, :name => "...\nbeatiful_name\n for project")}.should raise_error(ActiveRecord::RecordInvalid)
    end
  end
end
