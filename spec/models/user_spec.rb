# -*- encoding : utf-8 -*-
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
      puts "other user roles are #{other_user.target_roles(@project)}"
      other_user.best_role(@project).should == nil
    end
  end

  context 'for group project' do
    before(:each) do
      @project.relations.destroy_all
      @project.update_attribute :owner, @group
      @project.relations.create :actor_id => @project.owner.id, :actor_type => @project.owner.class.to_s, :role => 'admin'
    end

    context 'for group member' do
      context 'with reader rights' do
        before(:each) do
          @group.actors.create(:actor_id => @user.id, :actor_type => 'User', :role => 'reader')
        end

        it 'should have reader role to project' do
          @user.best_role(@project).should == 'reader'
        end
      end
    end
  end
end
