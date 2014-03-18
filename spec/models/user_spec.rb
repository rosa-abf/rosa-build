require 'spec_helper'

describe User do
  before { stub_symlink_methods }
  before(:each) do
    @project = FactoryGirl.create(:project)
    @group = FactoryGirl.create(:group)
    @user = FactoryGirl.create(:user)
  end

  context 'for own project' do
    it 'should have admin role' do
      @project.owner.best_role(@project).should == 'admin'
    end
  end

  context 'other user' do
    it 'should have not right to project' do
      other_user = FactoryGirl.create(:user)
      other_user.best_role(@project).should == nil
    end
  end

  %w(reader writer admin).each do |group_role|
    context "for group with #{group_role} role in project" do
      before(:each) { create_relation(@project, @group, group_role) }

      %w(reader writer admin).each do |role|
        context "for user with #{role} role in group" do
          before(:each) { create_actor_relation(@group, @user, role) }

          it "should have #{group_role} role to project" do
            @user.best_role(@project).should == group_role
          end
        end
      end
    end
  end

  context 'for group project' do
    before(:each) do
      @project.relations.destroy_all

      @project.owner = @group
      @project.save
      create_relation(@project, @project.owner, 'admin')
    end

    %w(reader writer admin).each do |role|
      context "for user with #{role} role in group" do
        before(:each) { create_actor_relation(@group, @user, role) }

        it "should have #{role} role to project" do
          @user.best_role(@project).should == role
        end
      end
    end

    %w(reader writer admin).each do |role|
      context "for user with #{role} role in project" do
        before(:each) { create_relation(@project, @user, role) }

        it "should have #{role} role to project" do
          @user.best_role(@project).should == role
        end
      end
    end

    context "for user with reader role in group and writer role in project" do
      it "should have writer best role to project" do
        create_actor_relation(@group, @user, 'reader')
        create_relation(@project, @user, 'writer')
        @user.best_role(@project).should == 'writer'
      end
    end

    context "for user with admin role in group and reader role in project" do
      it "should have admin best role to project" do
        create_actor_relation(@group, @user, 'admin')
        create_relation(@project, @user, 'reader')
        @user.best_role(@project).should == 'admin'
      end
    end
  end

  it {should_not allow_value("new_user\nHello World!").for(:uname)}
end
